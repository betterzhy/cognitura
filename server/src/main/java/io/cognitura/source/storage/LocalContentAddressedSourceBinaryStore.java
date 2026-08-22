package io.cognitura.source.storage;

import io.cognitura.source.application.command.SourceBinaryStore;
import io.cognitura.source.domain.SourceHash;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Set;
import java.util.regex.Pattern;

public final class LocalContentAddressedSourceBinaryStore implements SourceBinaryStore {

    private static final int COPY_BUFFER_BYTES = 8 * 1024;
    private static final Pattern LOCATION = Pattern.compile("sha256:([0-9a-f]{64})");

    private final Path root;
    private final long maxBytes;
    private final Set<String> supportedMediaTypes;
    private final NoReplacePublisher noReplacePublisher;

    public LocalContentAddressedSourceBinaryStore(
            Path root,
            long maxBytes,
            Set<String> supportedMediaTypes) {
        this(root, maxBytes, supportedMediaTypes,
                (source, target) -> Files.createLink(target, source));
    }

    LocalContentAddressedSourceBinaryStore(
            Path root,
            long maxBytes,
            Set<String> supportedMediaTypes,
            NoReplacePublisher noReplacePublisher) {
        Objects.requireNonNull(root, "root");
        Objects.requireNonNull(supportedMediaTypes, "supportedMediaTypes");
        this.noReplacePublisher = Objects.requireNonNull(
                noReplacePublisher, "noReplacePublisher");
        if (maxBytes <= 0) {
            throw new IllegalArgumentException("SOURCE_BINARY_LIMIT_INVALID");
        }
        if (supportedMediaTypes.isEmpty()
                || supportedMediaTypes.stream().anyMatch(value -> value == null || value.isBlank())) {
            throw new IllegalArgumentException("SOURCE_BINARY_MEDIA_TYPES_INVALID");
        }
        this.maxBytes = maxBytes;
        this.supportedMediaTypes = Set.copyOf(supportedMediaTypes);
        this.root = prepareRoot(root);
    }

    @Override
    public StoredBinary store(
            InputStream content,
            long declaredLength,
            SourceHash declaredSha256,
            String mediaType) {
        Objects.requireNonNull(content, "content");
        Objects.requireNonNull(declaredSha256, "declaredSha256");
        if (!supportedMediaTypes.contains(mediaType)) {
            throw new IllegalArgumentException("SOURCE_BINARY_MEDIA_TYPE_UNSUPPORTED");
        }
        if (declaredLength < 0) {
            throw new IllegalArgumentException("SOURCE_BINARY_DECLARED_LENGTH_INVALID");
        }
        if (declaredLength > maxBytes) {
            throw new IllegalArgumentException("SOURCE_BINARY_LIMIT_EXCEEDED");
        }

        Path temporary = null;
        try {
            temporary = Files.createTempFile(root, ".tmp-", ".part");
            StreamedBinary streamed = streamOnce(content, temporary);
            if (streamed.byteLength() == 0) {
                throw new IllegalArgumentException("SOURCE_BINARY_EMPTY");
            }
            if (streamed.byteLength() != declaredLength) {
                throw new IllegalArgumentException("SOURCE_BINARY_DECLARED_LENGTH_MISMATCH");
            }
            if (!streamed.contentSha256().equals(declaredSha256)) {
                throw new IllegalArgumentException("SOURCE_BINARY_DECLARED_HASH_MISMATCH");
            }

            Path target = targetPath(streamed.contentSha256(), true);
            String location = location(streamed.contentSha256());
            if (Files.exists(target, LinkOption.NOFOLLOW_LINKS)) {
                verifyExisting(target, streamed.contentSha256(), streamed.byteLength());
                return new StoredBinary(
                        streamed.contentSha256(), streamed.byteLength(), mediaType, location, true);
            }
            try {
                noReplacePublisher.publish(temporary, target);
                Files.delete(temporary);
                temporary = null;
                return new StoredBinary(
                        streamed.contentSha256(), streamed.byteLength(), mediaType, location, false);
            } catch (FileAlreadyExistsException race) {
                verifyExisting(target, streamed.contentSha256(), streamed.byteLength());
                return new StoredBinary(
                        streamed.contentSha256(), streamed.byteLength(), mediaType, location, true);
            } catch (UnsupportedOperationException unsupported) {
                throw new IllegalStateException("SOURCE_BINARY_ATOMIC_NO_REPLACE_REQUIRED");
            }
        } catch (IllegalArgumentException | IllegalStateException error) {
            throw error;
        } catch (IOException error) {
            throw new IllegalStateException("SOURCE_BINARY_STORAGE_FAILURE");
        } finally {
            deleteTemporary(temporary);
        }
    }

    @Override
    public InputStream open(String opaqueLocation) {
        var matcher = opaqueLocation == null ? null : LOCATION.matcher(opaqueLocation);
        if (matcher == null || !matcher.matches()) {
            throw new IllegalArgumentException("SOURCE_BINARY_LOCATION_INVALID");
        }
        SourceHash hash = SourceHash.ofHex(matcher.group(1));
        try {
            Path target = targetPath(hash, false);
            if (!Files.isRegularFile(target, LinkOption.NOFOLLOW_LINKS)
                    || Files.isSymbolicLink(target)) {
                throw new IllegalStateException("SOURCE_BINARY_NOT_FOUND");
            }
            verifyExisting(target, hash, Files.size(target));
            return Files.newInputStream(target);
        } catch (IllegalStateException error) {
            throw error;
        } catch (IOException error) {
            throw new IllegalStateException("SOURCE_BINARY_STORAGE_FAILURE");
        }
    }

    private StreamedBinary streamOnce(InputStream content, Path temporary) throws IOException {
        MessageDigest digest = sha256Digest();
        long byteLength = 0;
        byte[] buffer = new byte[COPY_BUFFER_BYTES];
        try (OutputStream output = Files.newOutputStream(temporary)) {
            int count;
            while ((count = content.read(buffer)) != -1) {
                if (count == 0) {
                    continue;
                }
                if (byteLength > maxBytes - count) {
                    throw new IllegalArgumentException("SOURCE_BINARY_LIMIT_EXCEEDED");
                }
                output.write(buffer, 0, count);
                digest.update(buffer, 0, count);
                byteLength += count;
            }
        }
        return new StreamedBinary(
                SourceHash.ofHex(HexFormat.of().formatHex(digest.digest())), byteLength);
    }

    private Path targetPath(SourceHash hash, boolean createDirectories) throws IOException {
        Path shaRoot = requireDirectory(root.resolve("sha256"), createDirectories);
        Path first = requireDirectory(shaRoot.resolve(hash.value().substring(0, 2)), createDirectories);
        Path second = requireDirectory(first.resolve(hash.value().substring(2, 4)), createDirectories);
        Path target = second.resolve(hash.value()).normalize();
        if (!target.startsWith(root)) {
            throw new IllegalStateException("SOURCE_BINARY_CAS_PATH_UNSAFE");
        }
        if (Files.isSymbolicLink(target)) {
            throw new IllegalStateException("SOURCE_BINARY_CAS_PATH_UNSAFE");
        }
        return target;
    }

    private static Path requireDirectory(Path path, boolean create) throws IOException {
        if (!Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
            if (!create) {
                throw new IllegalStateException("SOURCE_BINARY_NOT_FOUND");
            }
            try {
                Files.createDirectory(path);
            } catch (FileAlreadyExistsException race) {
                // Validate the winner below.
            }
        }
        if (Files.isSymbolicLink(path)
                || !Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS)) {
            throw new IllegalStateException("SOURCE_BINARY_CAS_PATH_UNSAFE");
        }
        return path;
    }

    private static Path prepareRoot(Path requestedRoot) {
        Path absolute = requestedRoot.toAbsolutePath().normalize();
        if (Files.isSymbolicLink(absolute)) {
            throw new IllegalArgumentException("SOURCE_BINARY_ROOT_SYMLINK_FORBIDDEN");
        }
        Path parent = absolute.getParent();
        if (parent == null) {
            throw new IllegalArgumentException("SOURCE_BINARY_ROOT_INVALID");
        }
        try {
            Path canonicalParent = parent.toRealPath();
            Path canonicalRoot = canonicalParent.resolve(absolute.getFileName());
            if (!Files.exists(canonicalRoot, LinkOption.NOFOLLOW_LINKS)) {
                Files.createDirectory(canonicalRoot);
            }
            if (Files.isSymbolicLink(canonicalRoot)
                    || !Files.isDirectory(canonicalRoot, LinkOption.NOFOLLOW_LINKS)) {
                throw new IllegalArgumentException("SOURCE_BINARY_ROOT_SYMLINK_FORBIDDEN");
            }
            return canonicalRoot;
        } catch (IllegalArgumentException error) {
            throw error;
        } catch (IOException error) {
            throw new IllegalArgumentException("SOURCE_BINARY_ROOT_INVALID");
        }
    }

    private static void verifyExisting(Path target, SourceHash hash, long expectedLength)
            throws IOException {
        if (!Files.isRegularFile(target, LinkOption.NOFOLLOW_LINKS)
                || Files.isSymbolicLink(target)
                || Files.size(target) != expectedLength
                || !digest(target).equals(hash)) {
            throw new IllegalStateException("SOURCE_BINARY_CAS_TARGET_CORRUPT");
        }
    }

    private static SourceHash digest(Path path) throws IOException {
        MessageDigest digest = sha256Digest();
        byte[] buffer = new byte[COPY_BUFFER_BYTES];
        try (InputStream input = Files.newInputStream(path)) {
            int count;
            while ((count = input.read(buffer)) != -1) {
                if (count > 0) {
                    digest.update(buffer, 0, count);
                }
            }
        }
        return SourceHash.ofHex(HexFormat.of().formatHex(digest.digest()));
    }

    private static MessageDigest sha256Digest() {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE");
        }
    }

    private static String location(SourceHash hash) {
        return "sha256:" + hash.value();
    }

    private static void deleteTemporary(Path temporary) {
        if (temporary == null) {
            return;
        }
        try {
            Files.deleteIfExists(temporary);
        } catch (IOException ignored) {
            throw new IllegalStateException("SOURCE_BINARY_TEMPORARY_CLEANUP_FAILED");
        }
    }

    @FunctionalInterface
    interface NoReplacePublisher {
        void publish(Path source, Path target) throws IOException;
    }

    private record StreamedBinary(SourceHash contentSha256, long byteLength) {
    }
}
