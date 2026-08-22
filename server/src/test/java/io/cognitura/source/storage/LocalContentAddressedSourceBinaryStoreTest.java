package io.cognitura.source.storage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.application.command.SourceBinaryStore;
import io.cognitura.source.domain.SourceHash;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.attribute.FileTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class LocalContentAddressedSourceBinaryStoreTest {

    private static final String DOCX =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

    @TempDir
    Path temporaryDirectory;

    @Test
    void streamsLargeContentOnceAndReturnsStableOpaqueCasIdentity() throws Exception {
        byte[] content = deterministicBytes(196_613);
        SourceHash hash = SourceHash.sha256(content);
        OnePassInputStream input = new OnePassInputStream(content);
        LocalContentAddressedSourceBinaryStore store = store(512_000);

        SourceBinaryStore.StoredBinary stored =
                store.store(input, content.length, hash, DOCX);

        assertThat(input.bytesRead()).isEqualTo(content.length);
        assertThat(stored).isEqualTo(new SourceBinaryStore.StoredBinary(
                hash, content.length, DOCX, "sha256:" + hash.value(), false));
        Path target = target(hash);
        assertThat(Files.isRegularFile(target, LinkOption.NOFOLLOW_LINKS)).isTrue();
        assertThat(Files.readAllBytes(target)).containsExactly(content);
        try (InputStream reopened = store.open(stored.opaqueLocation())) {
            assertThat(reopened.readAllBytes()).containsExactly(content);
        }
        assertNoTemporaryFiles();
    }

    @Test
    void validatesDeclarationsSizeAndMediaWithoutLeavingTemporaryBytes() throws Exception {
        byte[] content = "content".getBytes(StandardCharsets.UTF_8);
        SourceHash hash = SourceHash.sha256(content);
        LocalContentAddressedSourceBinaryStore store = store(8);

        assertThatThrownBy(() -> store.store(
                        new ByteArrayInputStream(content), content.length + 1L, hash, DOCX))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_BINARY_DECLARED_LENGTH_MISMATCH");
        assertThatThrownBy(() -> store.store(
                        new ByteArrayInputStream(content), content.length,
                        SourceHash.ofHex("f".repeat(64)), DOCX))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_BINARY_DECLARED_HASH_MISMATCH");
        assertThatThrownBy(() -> store.store(
                        new ByteArrayInputStream(new byte[0]), 0, SourceHash.sha256(new byte[0]), DOCX))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_BINARY_EMPTY");
        assertThatThrownBy(() -> store.store(
                        new ByteArrayInputStream(content), content.length, hash, "text/plain"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_BINARY_MEDIA_TYPE_UNSUPPORTED");
        byte[] overLimit = deterministicBytes(9);
        assertThatThrownBy(() -> store.store(
                        new ByteArrayInputStream(overLimit), 8,
                        SourceHash.sha256(overLimit), DOCX))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_BINARY_LIMIT_EXCEEDED");

        assertNoTemporaryFiles();
        assertThat(Files.walk(temporaryDirectory)
                .filter(Files::isRegularFile)
                .toList()).isEmpty();
    }

    @Test
    void reusesOnlyVerifiedExistingBytesAndNeverOverwritesCorruption() throws Exception {
        byte[] content = deterministicBytes(32_777);
        SourceHash hash = SourceHash.sha256(content);
        LocalContentAddressedSourceBinaryStore store = store(64_000);
        SourceBinaryStore.StoredBinary first = store.store(
                new ByteArrayInputStream(content), content.length, hash, DOCX);
        Path target = target(hash);
        FileTime preservedTime = FileTime.fromMillis(1_234_000L);
        Files.setLastModifiedTime(target, preservedTime);

        SourceBinaryStore.StoredBinary replay = store.store(
                new ByteArrayInputStream(content), content.length, hash, DOCX);

        assertThat(replay).isEqualTo(new SourceBinaryStore.StoredBinary(
                hash, content.length, DOCX, first.opaqueLocation(), true));
        assertThat(Files.getLastModifiedTime(target)).isEqualTo(preservedTime);

        byte[] corrupted = content.clone();
        corrupted[0] ^= 0x7f;
        Files.write(target, corrupted);
        assertThatThrownBy(() -> store.store(
                        new ByteArrayInputStream(content), content.length, hash, DOCX))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("SOURCE_BINARY_CAS_TARGET_CORRUPT");
        assertThat(Files.readAllBytes(target)).containsExactly(corrupted);
        assertNoTemporaryFiles();
    }

    @Test
    void concurrentDigestPublicationHasExactlyOneNonReplacingWinner() throws Exception {
        int writers = 8;
        byte[] content = deterministicBytes(262_151);
        SourceHash hash = SourceHash.sha256(content);
        LocalContentAddressedSourceBinaryStore store = store(512_000);
        CountDownLatch ready = new CountDownLatch(writers);
        CountDownLatch start = new CountDownLatch(1);
        var executor = Executors.newFixedThreadPool(writers);
        List<Future<SourceBinaryStore.StoredBinary>> futures = new ArrayList<>();
        try {
            for (int index = 0; index < writers; index++) {
                futures.add(executor.submit(() -> {
                    ready.countDown();
                    if (!start.await(10, TimeUnit.SECONDS)) {
                        throw new IllegalStateException("TEST_START_TIMEOUT");
                    }
                    return store.store(
                            new ByteArrayInputStream(content), content.length, hash, DOCX);
                }));
            }
            assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue();
            start.countDown();

            List<SourceBinaryStore.StoredBinary> results = new ArrayList<>();
            for (Future<SourceBinaryStore.StoredBinary> future : futures) {
                results.add(future.get(10, TimeUnit.SECONDS));
            }
            assertThat(results.stream().filter(result -> !result.reused()).count()).isEqualTo(1);
            assertThat(results.stream().filter(SourceBinaryStore.StoredBinary::reused).count())
                    .isEqualTo(writers - 1L);
            assertThat(Files.readAllBytes(target(hash))).containsExactly(content);
            assertNoTemporaryFiles();
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void rejectsUntrustedLocationsAndSymbolicLinkRootsOrSegments() throws Exception {
        LocalContentAddressedSourceBinaryStore store = store(64_000);
        for (String location : Set.of("../secret", "file:/tmp/secret", "sha256:../secret",
                "sha256:" + "A".repeat(64))) {
            assertThatThrownBy(() -> store.open(location))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessage("SOURCE_BINARY_LOCATION_INVALID")
                    .hasMessageNotContaining(location);
        }

        Path realRoot = temporaryDirectory.resolve("real-root");
        Files.createDirectory(realRoot);
        Path rootLink = temporaryDirectory.resolve("root-link");
        Files.createSymbolicLink(rootLink, realRoot);
        assertThatThrownBy(() -> new LocalContentAddressedSourceBinaryStore(
                        rootLink, 64_000, Set.of(DOCX)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("SOURCE_BINARY_ROOT_SYMLINK_FORBIDDEN");

        Path segmentRoot = temporaryDirectory.resolve("segment-root");
        Files.createDirectory(segmentRoot);
        Path external = temporaryDirectory.resolve("external");
        Files.createDirectory(external);
        Files.createSymbolicLink(segmentRoot.resolve("sha256"), external);
        LocalContentAddressedSourceBinaryStore segmentStore =
                new LocalContentAddressedSourceBinaryStore(segmentRoot, 64_000, Set.of(DOCX));
        byte[] content = "segment".getBytes(StandardCharsets.UTF_8);
        assertThatThrownBy(() -> segmentStore.store(
                        new ByteArrayInputStream(content), content.length,
                        SourceHash.sha256(content), DOCX))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("SOURCE_BINARY_CAS_PATH_UNSAFE");
        assertThat(Files.list(external).toList()).isEmpty();
    }

    @Test
    void atomicNoReplaceFailureFailsClosedAndCleansTemporaryFile() throws Exception {
        LocalContentAddressedSourceBinaryStore store = new LocalContentAddressedSourceBinaryStore(
                temporaryDirectory.resolve("cas"), 64_000, Set.of(DOCX),
                (source, target) -> {
                    throw new UnsupportedOperationException("test");
                });
        byte[] content = deterministicBytes(4_096);

        assertThatThrownBy(() -> store.store(
                        new ByteArrayInputStream(content), content.length,
                        SourceHash.sha256(content), DOCX))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("SOURCE_BINARY_ATOMIC_NO_REPLACE_REQUIRED")
                .hasMessageNotContaining(temporaryDirectory.toString());
        assertNoTemporaryFiles();
        assertThat(Files.walk(temporaryDirectory)
                .filter(Files::isRegularFile)
                .toList()).isEmpty();
    }

    private LocalContentAddressedSourceBinaryStore store(long maxBytes) {
        return new LocalContentAddressedSourceBinaryStore(
                temporaryDirectory.resolve("cas"), maxBytes, Set.of(DOCX));
    }

    private Path target(SourceHash hash) {
        return temporaryDirectory.resolve("cas/sha256")
                .resolve(hash.value().substring(0, 2))
                .resolve(hash.value().substring(2, 4))
                .resolve(hash.value());
    }

    private void assertNoTemporaryFiles() throws IOException {
        if (!Files.exists(temporaryDirectory)) {
            return;
        }
        assertThat(Files.walk(temporaryDirectory)
                .filter(path -> path.getFileName().toString().contains(".tmp-"))
                .toList()).isEmpty();
    }

    private static byte[] deterministicBytes(int size) {
        byte[] bytes = new byte[size];
        for (int index = 0; index < bytes.length; index++) {
            bytes[index] = (byte) (index * 31 + 7);
        }
        return bytes;
    }

    private static final class OnePassInputStream extends InputStream {
        private final byte[] content;
        private int position;
        private long bytesRead;

        private OnePassInputStream(byte[] content) {
            this.content = content.clone();
        }

        @Override
        public int read() {
            if (position == content.length) {
                return -1;
            }
            bytesRead++;
            return content[position++] & 0xff;
        }

        @Override
        public int read(byte[] target, int offset, int length) {
            if (position == content.length) {
                return -1;
            }
            int count = Math.min(Math.min(length, 997), content.length - position);
            System.arraycopy(content, position, target, offset, count);
            position += count;
            bytesRead += count;
            return count;
        }

        @Override
        public boolean markSupported() {
            return false;
        }

        private long bytesRead() {
            return bytesRead;
        }
    }
}
