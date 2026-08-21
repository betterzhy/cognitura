package io.cognitura.source.application.command;

import io.cognitura.source.domain.SourceHash;
import java.io.InputStream;
import java.util.Objects;

public interface SourceBinaryStore {

    StoredBinary store(
            InputStream content,
            long declaredLength,
            SourceHash declaredSha256,
            String mediaType);

    InputStream open(String opaqueLocation);

    record StoredBinary(
            SourceHash contentSha256,
            long byteLength,
            String mediaType,
            String opaqueLocation,
            boolean reused) {

        public StoredBinary {
            Objects.requireNonNull(contentSha256, "contentSha256");
            Objects.requireNonNull(mediaType, "mediaType");
            Objects.requireNonNull(opaqueLocation, "opaqueLocation");
            if (byteLength <= 0) {
                throw new IllegalArgumentException("SOURCE_BINARY_LENGTH_INVALID");
            }
        }
    }
}
