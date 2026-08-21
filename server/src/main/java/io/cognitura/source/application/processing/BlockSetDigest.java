package io.cognitura.source.application.processing;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;

public record BlockSetDigest(String value) {

    private static final Pattern SHA_256 = Pattern.compile("[0-9a-f]{64}");
    public BlockSetDigest {
        Objects.requireNonNull(value, "value");
        if (!SHA_256.matcher(value).matches()) {
            throw new IllegalArgumentException("BLOCK_SET_DIGEST_MUST_BE_64_LOWERCASE_HEX");
        }
    }

    public static BlockSetDigest compute(CandidateBlockSet blockSet) {
        Objects.requireNonNull(blockSet, "blockSet");
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                writeText(output, blockSet.sourceDocumentId());
                writeText(output, blockSet.revisionId());
                writeText(output, blockSet.parseCompleteness().name());
                writeText(output, blockSet.partialAcceptanceStatus().name());
                writeText(output, blockSet.omissionsDigest().value());
                output.writeInt(blockSet.blocks().size());
                for (CandidateBlockSet.Block block : blockSet.blocks()) {
                    byte[] canonical = block.canonicalBytes();
                    output.writeInt(canonical.length);
                    output.write(canonical);
                }
            }
            return sha256(bytes.toByteArray());
        } catch (IOException error) {
            throw new IllegalStateException("BLOCK_SET_CANONICAL_ENCODING_FAILED", error);
        }
    }

    public static BlockSetDigest computeOmissions(List<CandidateBlockSet.Omission> omissions) {
        Objects.requireNonNull(omissions, "omissions");
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                output.writeInt(omissions.size());
                for (CandidateBlockSet.Omission omission : omissions) {
                    byte[] canonical = Objects.requireNonNull(omission, "omission").canonicalBytes();
                    output.writeInt(canonical.length);
                    output.write(canonical);
                }
            }
            return sha256(bytes.toByteArray());
        } catch (IOException error) {
            throw new IllegalStateException("OMISSION_LIST_ENCODING_FAILED", error);
        }
    }

    private static void writeText(DataOutputStream output, String value) throws IOException {
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        output.writeInt(bytes.length);
        output.write(bytes);
    }

    private static BlockSetDigest sha256(byte[] bytes) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
            return new BlockSetDigest(HexFormat.of().formatHex(digest));
        } catch (NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA_256_ALGORITHM_UNAVAILABLE", error);
        }
    }
}
