package io.cognitura.source.docx.image;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.cognitura.source.docx.security.DocxRelationshipClassifier;
import io.cognitura.source.docx.security.DocxSecurityGate;
import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.domain.SourceDomainException;
import io.cognitura.source.domain.SourceHash;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class ImageRelationshipProjectorTest {

    private static final byte[] PARAGRAPH_PNG = bytes("paragraph-png");
    private static final byte[] PARAGRAPH_JPEG = bytes("paragraph-jpeg");
    private static final byte[] CELL_ONE_PNG = bytes("cell-one-png");
    private static final byte[] CELL_TWO_PNG = bytes("cell-two-png");

    @TempDir
    Path temporaryDirectory;

    @Test
    void projectsParagraphAndTableImagesWithStableAnchorsAndImmutableMediaEvidence()
            throws IOException {
        List<ParentLookup> parentLookups = new ArrayList<>();
        List<StoredMedia> storedMedia = new ArrayList<>();

        try (SafeDocxPackage safePackage = openPackage("internal.docx", baseEntries())) {
            ImageRelationshipProjector.Projection projection = new ImageRelationshipProjector()
                    .project(
                            safePackage,
                            (sourcePart, sourceElementIndex, anchorKind, rowIndex, columnIndex) -> {
                                ParentLookup lookup = new ParentLookup(
                                        sourcePart,
                                        sourceElementIndex,
                                        anchorKind,
                                        rowIndex,
                                        columnIndex);
                                parentLookups.add(lookup);
                                return anchorKind == ImageAnchor.AnchorKind.PARAGRAPH_INLINE
                                        ? "block-paragraph"
                                        : "block-table";
                            },
                            (sourcePart, relationshipId, mediaType, content, digest) -> {
                                storedMedia.add(new StoredMedia(
                                        sourcePart,
                                        relationshipId,
                                        mediaType,
                                        content.clone(),
                                        digest));
                                content[0] ^= 0x7f;
                                return new ImmutableMediaRef("media:" + digest.contentSha256().value());
                            });

            assertThat(projection.images()).hasSize(4);
            assertThat(projection.images())
                    .extracting(ImageRelationshipProjector.ProjectedImage::sourceOrder)
                    .containsExactly(1, 2, 4, 5);
            assertThat(projection.images())
                    .extracting(ImageRelationshipProjector.ProjectedImage::relationshipId)
                    .containsExactly("rIdPng", "rIdJpeg", "rIdCellOne", "rIdCellTwo");
            assertThat(projection.images())
                    .extracting(image -> image.anchor().parentBlockId())
                    .containsExactly(
                            "block-paragraph", "block-paragraph", "block-table", "block-table");
            assertThat(projection.images())
                    .extracting(image -> image.anchor().textOffset())
                    .containsExactly(2, 4, 2, 5);
            assertThat(projection.images())
                    .extracting(image -> image.anchor().childOrdinal())
                    .containsExactly(0, 1, 0, 1);
            assertThat(projection.images())
                    .extracting(image -> image.anchor().anchorKind())
                    .containsExactly(
                            ImageAnchor.AnchorKind.PARAGRAPH_INLINE,
                            ImageAnchor.AnchorKind.PARAGRAPH_INLINE,
                            ImageAnchor.AnchorKind.TABLE_CELL_INLINE,
                            ImageAnchor.AnchorKind.TABLE_CELL_INLINE);
            assertThat(projection.images())
                    .extracting(image -> image.anchor().rowIndex())
                    .containsExactly(null, null, 0, 0);
            assertThat(projection.images())
                    .extracting(image -> image.anchor().columnIndex())
                    .containsExactly(null, null, 0, 0);
            assertThat(projection.images())
                    .allSatisfy(image -> {
                        assertThat(image.relationshipMode())
                                .isEqualTo(DocxRelationshipClassifier.Mode.INTERNAL);
                        assertThat(image.externalTargetLiteralSha256()).isNull();
                        assertThat(image.securityDisclosure()).isNull();
                        assertThat(image.mediaRef()).isNotNull();
                        assertThat(image.contentSha256()).isNotNull();
                        assertThat(image.contentHash()).isNotNull();
                    });
            assertThat(projection.images())
                    .extracting(ImageRelationshipProjector.ProjectedImage::mediaType)
                    .containsExactly("image/png", "image/jpeg", "image/png", "image/png");
            assertThat(projection.images())
                    .extracting(ImageRelationshipProjector.ProjectedImage::byteLength)
                    .containsExactly(
                            (long) PARAGRAPH_PNG.length,
                            (long) PARAGRAPH_JPEG.length,
                            (long) CELL_ONE_PNG.length,
                            (long) CELL_TWO_PNG.length);
            assertThat(projection.revisionDiagnostics()).isEmpty();
        }

        assertThat(parentLookups).hasSize(4);
        assertThat(parentLookups)
                .extracting(ParentLookup::sourcePart)
                .containsOnly("word/document.xml");
        assertThat(parentLookups.get(0).sourceElementIndex())
                .isEqualTo(parentLookups.get(1).sourceElementIndex());
        assertThat(parentLookups.get(2).sourceElementIndex())
                .isEqualTo(parentLookups.get(3).sourceElementIndex());
        assertThat(parentLookups.get(0).sourceElementIndex())
                .isNotEqualTo(parentLookups.get(2).sourceElementIndex());
        assertThat(storedMedia).hasSize(4);
        assertThat(storedMedia)
                .extracting(StoredMedia::content)
                .usingElementComparator((left, right) -> java.util.Arrays.compare(left, right))
                .containsExactly(PARAGRAPH_PNG, PARAGRAPH_JPEG, CELL_ONE_PNG, CELL_TWO_PNG);
        assertThat(storedMedia)
                .allSatisfy(stored -> {
                    assertThat(stored.sourcePart()).isEqualTo("word/document.xml");
                    assertThat(stored.digest().mediaType()).isEqualTo(stored.mediaType());
                    assertThat(stored.digest().byteLength()).isEqualTo(stored.content().length);
                    assertThat(stored.digest().contentSha256())
                            .isEqualTo(SourceHash.sha256(stored.content()));
                });
    }

    @Test
    void rejectsAnImageWhoseRelationshipIsMissing() throws IOException {
        LinkedHashMap<String, byte[]> entries = baseEntries();
        entries.put(
                "word/document.xml",
                resource("internal-images-document.xml")
                        .replace("rIdPng", "rIdAbsent")
                        .getBytes(StandardCharsets.UTF_8));

        try (SafeDocxPackage safePackage = openPackage("missing-relationship.docx", entries)) {
            assertThatThrownBy(() -> project(safePackage))
                    .isInstanceOf(SourceDomainException.class)
                    .hasMessageContaining("IMAGE_RELATIONSHIP_MISSING");
        }
    }

    @Test
    void changesBinaryAndCanonicalDigestsWhenVerifiedMediaBytesDrift() throws IOException {
        ImageRelationshipProjector.Projection original;
        try (SafeDocxPackage safePackage = openPackage("original.docx", baseEntries())) {
            original = project(safePackage);
        }
        LinkedHashMap<String, byte[]> driftedEntries = baseEntries();
        driftedEntries.put("word/media/paragraph.png", bytes("paragraph-png-drifted"));
        ImageRelationshipProjector.Projection drifted;
        try (SafeDocxPackage safePackage = openPackage("drifted.docx", driftedEntries)) {
            drifted = project(safePackage);
        }

        assertThat(drifted.images().get(0).contentSha256())
                .isNotEqualTo(original.images().get(0).contentSha256());
        assertThat(drifted.images().get(0).contentHash())
                .isNotEqualTo(original.images().get(0).contentHash());
        assertThat(drifted.images().subList(1, 4))
                .extracting(ImageRelationshipProjector.ProjectedImage::contentHash)
                .containsExactlyElementsOf(original.images().subList(1, 4).stream()
                        .map(ImageRelationshipProjector.ProjectedImage::contentHash)
                        .toList());
    }

    @Test
    void rejectsMissingOrConflictingMediaContentTypes() throws IOException {
        String contentTypes = resource("internal-images-content-types.xml");
        for (String invalid : List.of(
                contentTypes.replace(
                        "  <Default Extension=\"png\" ContentType=\"image/png\"/>\n", ""),
                contentTypes.replace(
                        "  <Default Extension=\"jpg\" ContentType=\"image/jpeg\"/>",
                        "  <Default Extension=\"jpg\" ContentType=\"image/jpeg\"/>\n"
                                + "  <Default Extension=\"JPG\" ContentType=\"image/other\"/>"))) {
            LinkedHashMap<String, byte[]> entries = baseEntries();
            entries.put("[Content_Types].xml", invalid.getBytes(StandardCharsets.UTF_8));
            try (SafeDocxPackage safePackage = openPackage("bad-content-type.docx", entries)) {
                assertThatThrownBy(() -> project(safePackage))
                        .isInstanceOf(SourceDomainException.class)
                        .hasMessageContaining("IMAGE_MEDIA_TYPE_INVALID");
            }
        }
    }

    private ImageRelationshipProjector.Projection project(SafeDocxPackage safePackage) {
        return new ImageRelationshipProjector().project(
                safePackage,
                (sourcePart, sourceElementIndex, anchorKind, rowIndex, columnIndex) ->
                        anchorKind == ImageAnchor.AnchorKind.PARAGRAPH_INLINE
                                ? "block-paragraph"
                                : "block-table",
                (sourcePart, relationshipId, mediaType, content, digest) ->
                        new ImmutableMediaRef("media:" + digest.contentSha256().value()));
    }

    private SafeDocxPackage openPackage(String fileName, LinkedHashMap<String, byte[]> entries)
            throws IOException {
        Path path = temporaryDirectory.resolve(fileName);
        Files.write(path, zipBytes(entries));
        return new DocxSecurityGate().open(path);
    }

    private static LinkedHashMap<String, byte[]> baseEntries() {
        LinkedHashMap<String, byte[]> entries = new LinkedHashMap<>();
        entries.put("[Content_Types].xml", resourceBytes("internal-images-content-types.xml"));
        entries.put("_rels/.rels", resourceBytes("root-office-document.xml.rels"));
        entries.put("word/document.xml", resourceBytes("internal-images-document.xml"));
        entries.put(
                "word/_rels/document.xml.rels",
                resourceBytes("internal-images-document.xml.rels"));
        entries.put("word/media/paragraph.png", PARAGRAPH_PNG);
        entries.put("word/media/paragraph.jpg", PARAGRAPH_JPEG);
        entries.put("word/media/cell-one.png", CELL_ONE_PNG);
        entries.put("word/media/cell-two.png", CELL_TWO_PNG);
        return entries;
    }

    private static byte[] zipBytes(LinkedHashMap<String, byte[]> packageEntries) throws IOException {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (ZipOutputStream zip = new ZipOutputStream(bytes)) {
            for (Map.Entry<String, byte[]> entry : packageEntries.entrySet()) {
                zip.putNextEntry(new ZipEntry(entry.getKey()));
                zip.write(entry.getValue());
                zip.closeEntry();
            }
        }
        return bytes.toByteArray();
    }

    private static byte[] resourceBytes(String name) {
        return resource(name).getBytes(StandardCharsets.UTF_8);
    }

    private static String resource(String name) {
        try (InputStream input = ImageRelationshipProjectorTest.class.getResourceAsStream(
                "/docx/image/" + name)) {
            if (input == null) {
                throw new IllegalStateException("MISSING_TEST_RESOURCE:" + name);
            }
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException error) {
            throw new IllegalStateException("FAILED_TO_READ_TEST_RESOURCE:" + name, error);
        }
    }

    private static byte[] bytes(String value) {
        return value.getBytes(StandardCharsets.UTF_8);
    }

    private record ParentLookup(
            String sourcePart,
            int sourceElementIndex,
            ImageAnchor.AnchorKind anchorKind,
            Integer rowIndex,
            Integer columnIndex) {}

    private record StoredMedia(
            String sourcePart,
            String relationshipId,
            String mediaType,
            byte[] content,
            MediaDigest digest) {}
}
