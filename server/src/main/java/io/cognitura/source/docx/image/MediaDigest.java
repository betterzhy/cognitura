package io.cognitura.source.docx.image;

import io.cognitura.source.domain.SourceHash;
import java.util.Locale;
import java.util.Objects;

public record MediaDigest(String mediaType, long byteLength, SourceHash contentSha256) {

    public MediaDigest {
        if (mediaType == null
                || mediaType.isBlank()
                || !mediaType.equals(mediaType.toLowerCase(Locale.ROOT))
                || !mediaType.startsWith("image/")) {
            throw new IllegalArgumentException("IMAGE_MEDIA_TYPE_INVALID");
        }
        if (byteLength < 0) {
            throw new IllegalArgumentException("IMAGE_BYTE_LENGTH_INVALID");
        }
        Objects.requireNonNull(contentSha256, "contentSha256");
    }
}
