package io.cognitura.source.api.query;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.regex.Pattern;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public final class SourcePreviewCursor {

    private static final byte[] MAGIC = "CSPC".getBytes(StandardCharsets.US_ASCII);
    private static final int VERSION = 1;
    private static final int SIGNATURE_BYTES = 32;
    private static final int MAX_TOKEN_LENGTH = 2048;
    private static final int MAX_IDENTIFIER_BYTES = 128;
    private static final Pattern IDENTIFIER =
            Pattern.compile("[A-Za-z0-9][A-Za-z0-9._:-]{0,127}");
    private static final Base64.Encoder ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder DECODER = Base64.getUrlDecoder();

    private final byte[] signingKey;

    public SourcePreviewCursor(byte[] signingKey) {
        if (signingKey == null || signingKey.length < SIGNATURE_BYTES) {
            throw new IllegalArgumentException("PREVIEW_CURSOR_SIGNING_KEY_INVALID");
        }
        this.signingKey = signingKey.clone();
    }

    public String encode(
            String workspaceId,
            String sourceDocumentId,
            String sourceProcessingRevisionId,
            int lastSourceOrder) {
        requireIdentifier(workspaceId);
        requireIdentifier(sourceDocumentId);
        requireIdentifier(sourceProcessingRevisionId);
        if (lastSourceOrder < 0) throw paginationInvalid();
        try {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            try (DataOutputStream output = new DataOutputStream(bytes)) {
                output.write(MAGIC);
                output.writeByte(VERSION);
                writeText(output, workspaceId);
                writeText(output, sourceDocumentId);
                writeText(output, sourceProcessingRevisionId);
                output.writeInt(lastSourceOrder);
            }
            byte[] payload = bytes.toByteArray();
            return ENCODER.encodeToString(payload) + "." + ENCODER.encodeToString(sign(payload));
        } catch (IOException error) {
            throw new IllegalStateException("PREVIEW_CURSOR_ENCODING_FAILED", error);
        }
    }

    public int decode(
            String token,
            String expectedWorkspaceId,
            String expectedSourceDocumentId,
            String expectedSourceProcessingRevisionId) {
        requireIdentifier(expectedWorkspaceId);
        requireIdentifier(expectedSourceDocumentId);
        requireIdentifier(expectedSourceProcessingRevisionId);
        if (token == null || token.isBlank() || token.length() > MAX_TOKEN_LENGTH) {
            throw paginationInvalid();
        }
        try {
            int separator = token.indexOf('.');
            if (separator <= 0 || separator != token.lastIndexOf('.')) throw paginationInvalid();
            byte[] payload = DECODER.decode(token.substring(0, separator));
            byte[] submittedSignature = DECODER.decode(token.substring(separator + 1));
            if (submittedSignature.length != SIGNATURE_BYTES
                    || !MessageDigest.isEqual(sign(payload), submittedSignature)) {
                throw paginationInvalid();
            }
            try (DataInputStream input = new DataInputStream(new ByteArrayInputStream(payload))) {
                if (!MessageDigest.isEqual(input.readNBytes(MAGIC.length), MAGIC)
                        || input.readUnsignedByte() != VERSION) {
                    throw paginationInvalid();
                }
                String workspaceId = readText(input);
                String sourceDocumentId = readText(input);
                String revisionId = readText(input);
                int lastSourceOrder = input.readInt();
                if (input.available() != 0 || lastSourceOrder < 0
                        || !expectedWorkspaceId.equals(workspaceId)
                        || !expectedSourceDocumentId.equals(sourceDocumentId)
                        || !expectedSourceProcessingRevisionId.equals(revisionId)) {
                    throw paginationInvalid();
                }
                return lastSourceOrder;
            }
        } catch (IllegalArgumentException error) {
            if ("PAGINATION_INVALID".equals(error.getMessage())) throw error;
            throw paginationInvalid();
        } catch (IOException error) {
            throw paginationInvalid();
        }
    }

    private byte[] sign(byte[] payload) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(signingKey, "HmacSHA256"));
            return mac.doFinal(payload);
        } catch (GeneralSecurityException error) {
            throw new IllegalStateException("PREVIEW_CURSOR_HMAC_UNAVAILABLE", error);
        }
    }

    private static void writeText(DataOutputStream output, String value) throws IOException {
        byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
        output.writeInt(bytes.length);
        output.write(bytes);
    }

    private static String readText(DataInputStream input) throws IOException {
        int length = input.readInt();
        if (length <= 0 || length > MAX_IDENTIFIER_BYTES) throw paginationInvalid();
        byte[] bytes = input.readNBytes(length);
        if (bytes.length != length) throw paginationInvalid();
        String value = new String(bytes, StandardCharsets.UTF_8);
        requireIdentifier(value);
        return value;
    }

    private static void requireIdentifier(String value) {
        if (value == null || !IDENTIFIER.matcher(value).matches()) throw paginationInvalid();
    }

    private static IllegalArgumentException paginationInvalid() {
        return new IllegalArgumentException("PAGINATION_INVALID");
    }
}
