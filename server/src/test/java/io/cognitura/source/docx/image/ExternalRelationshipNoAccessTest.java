package io.cognitura.source.docx.image;

import static org.assertj.core.api.Assertions.assertThat;

import com.sun.net.httpserver.HttpServer;
import io.cognitura.source.docx.security.DocxRelationshipClassifier;
import io.cognitura.source.docx.security.DocxSecurityGate;
import io.cognitura.source.docx.security.SafeDocxPackage;
import io.cognitura.source.domain.SourceHash;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class ExternalRelationshipNoAccessTest {

    private static final String IMAGE_RELATIONSHIP_TYPE =
            "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image";

    @TempDir
    Path temporaryDirectory;

    @Test
    void projectsExternalImagesWithoutStatDnsFileReadOrNetworkAccess() throws Exception {
        AtomicInteger httpAccessCount = new AtomicInteger();
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/canary", exchange -> {
            httpAccessCount.incrementAndGet();
            exchange.sendResponseHeaders(204, -1);
            exchange.close();
        });
        server.start();

        Path fileCanary = temporaryDirectory.resolve("external-secret.png");
        Files.writeString(fileCanary, "must-not-be-read", StandardCharsets.UTF_8);
        String fileTarget = fileCanary.toUri().toString();
        String httpTarget = "http://127.0.0.1:" + server.getAddress().getPort() + "/canary";
        String dnsTarget = "https://w1-i06-canary.invalid/resource";
        Path packagePath = writePackage(
                "external.docx", relationships(fileTarget, httpTarget, dnsTarget));

        Path javaExecutable = Path.of(System.getProperty("java.home"), "bin", "java");
        Process process = new ProcessBuilder(
                        javaExecutable.toString(),
                        "-Djava.security.manager=allow",
                        "-cp",
                        System.getProperty("java.class.path"),
                        ProjectionProbe.class.getName(),
                        packagePath.toString(),
                        fileCanary.toString(),
                        Integer.toString(server.getAddress().getPort()),
                        fileTarget,
                        httpTarget,
                        dnsTarget)
                .redirectErrorStream(true)
                .start();
        boolean finished = process.waitFor(30, TimeUnit.SECONDS);
        if (!finished) {
            process.destroyForcibly();
        }
        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        server.stop(0);

        assertThat(finished).as(output).isTrue();
        assertThat(process.exitValue()).as(output).isZero();
        assertThat(output)
                .contains(
                        "BLOCKED_CANARIES=4",
                        "OPERATION_ATTEMPTS=0",
                        "PROJECTED_IMAGES=3",
                        "DIAGNOSTICS=3",
                        "DIGESTS_VERIFIED=3");
        assertThat(httpAccessCount).hasValue(0);
        assertThat(Files.readString(fileCanary, StandardCharsets.UTF_8))
                .isEqualTo("must-not-be-read");
    }

    @Test
    void externalTargetLiteralDriftChangesThePayloadAndDiagnosticDigest() throws IOException {
        String originalTarget = "https://example.invalid/original.png";
        String driftedTarget = "https://example.invalid/drifted.png";

        ImageRelationshipProjector.Projection original = project(writePackage(
                "original.docx", relationships(originalTarget, originalTarget, originalTarget)));
        ImageRelationshipProjector.Projection drifted = project(writePackage(
                "drifted.docx", relationships(driftedTarget, originalTarget, originalTarget)));

        SourceHash expected = SourceHash.sha256(driftedTarget.getBytes(StandardCharsets.UTF_8));
        assertThat(drifted.images().get(0).externalTargetLiteralSha256()).isEqualTo(expected);
        assertThat(drifted.revisionDiagnostics().get(0).externalTargetLiteralSha256())
                .isSameAs(drifted.images().get(0).externalTargetLiteralSha256());
        assertThat(drifted.images().get(0).contentHash())
                .isNotEqualTo(original.images().get(0).contentHash());
        assertThat(drifted.images().subList(1, 3))
                .extracting(ImageRelationshipProjector.ProjectedImage::contentHash)
                .containsExactlyElementsOf(original.images().subList(1, 3).stream()
                        .map(ImageRelationshipProjector.ProjectedImage::contentHash)
                        .toList());
    }

    private ImageRelationshipProjector.Projection project(Path path) {
        try (SafeDocxPackage safePackage = new DocxSecurityGate().open(path)) {
            return new ImageRelationshipProjector().project(
                    safePackage,
                    (sourcePart, sourceElementIndex, anchorKind, rowIndex, columnIndex) -> "block",
                    (sourcePart, relationshipId, mediaType, content, digest) -> {
                        throw new AssertionError("EXTERNAL_MEDIA_SINK_MUST_NOT_BE_CALLED");
                    });
        }
    }

    private Path writePackage(String fileName, String relationshipXml) throws IOException {
        LinkedHashMap<String, byte[]> entries = new LinkedHashMap<>();
        entries.put("[Content_Types].xml", resource("external-images-content-types.xml"));
        entries.put("_rels/.rels", resource("root-office-document.xml.rels"));
        entries.put("word/document.xml", resource("external-images-document.xml"));
        entries.put(
                "word/_rels/document.xml.rels",
                relationshipXml.getBytes(StandardCharsets.UTF_8));
        Path path = temporaryDirectory.resolve(fileName);
        Files.write(path, zipBytes(entries));
        return path;
    }

    private static String relationships(String fileTarget, String httpTarget, String dnsTarget) {
        return """
                <?xml version="1.0" encoding="UTF-8"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                """ + relationship("rFile", fileTarget)
                + relationship("rHttp", httpTarget)
                + relationship("rDns", dnsTarget)
                + "</Relationships>";
    }

    private static String relationship(String id, String target) {
        return "<Relationship Id=\"" + id + "\" Type=\"" + IMAGE_RELATIONSHIP_TYPE
                + "\" Target=\"" + target + "\" TargetMode=\"External\"/>";
    }

    private static byte[] zipBytes(LinkedHashMap<String, byte[]> entries) throws IOException {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (ZipOutputStream zip = new ZipOutputStream(bytes)) {
            for (Map.Entry<String, byte[]> entry : entries.entrySet()) {
                zip.putNextEntry(new ZipEntry(entry.getKey()));
                zip.write(entry.getValue());
                zip.closeEntry();
            }
        }
        return bytes.toByteArray();
    }

    private static byte[] resource(String name) {
        try (InputStream input = ExternalRelationshipNoAccessTest.class.getResourceAsStream(
                "/docx/image/" + name)) {
            if (input == null) {
                throw new IllegalStateException("MISSING_TEST_RESOURCE:" + name);
            }
            return input.readAllBytes();
        } catch (IOException error) {
            throw new IllegalStateException("FAILED_TO_READ_TEST_RESOURCE:" + name, error);
        }
    }

    private static final class ExternalAccessAudit {
        private final Path allowedPackage;
        private final Path javaHome;
        private final List<RuntimePath> runtimeClasspath;
        private final List<String> attempts = new ArrayList<>();

        private ExternalAccessAudit(Path allowedPackage) {
            this.allowedPackage = allowedPackage.toAbsolutePath().normalize();
            this.javaHome = Path.of(System.getProperty("java.home")).toAbsolutePath().normalize();
            this.runtimeClasspath = Arrays.stream(
                            System.getProperty("java.class.path").split(File.pathSeparator))
                    .map(Path::of)
                    .map(Path::toAbsolutePath)
                    .map(Path::normalize)
                    .map(path -> new RuntimePath(path, Files.isDirectory(path)))
                    .toList();
        }

        private boolean allowedRead(String file) {
            if (file == null) {
                return false;
            }
            try {
                Path candidate = Path.of(file).toAbsolutePath().normalize();
                return candidate.equals(allowedPackage)
                        || candidate.startsWith(javaHome)
                        || runtimeClasspath.stream().anyMatch(root -> root.directory()
                                ? candidate.startsWith(root.path())
                                : candidate.equals(root.path()))
                        || candidate.equals(Path.of("/dev/random"))
                        || candidate.equals(Path.of("/dev/urandom"));
            } catch (RuntimeException error) {
                return false;
            }
        }

        private void record(String access) {
            attempts.add(access);
        }

        private int attemptCount() {
            return attempts.size();
        }

        private String attemptSummary() {
            return String.join("|", attempts);
        }

        private record RuntimePath(Path path, boolean directory) {}
    }

    @SuppressWarnings("removal")
    private static final class NoExternalAccessSecurityManager extends SecurityManager {
        private final ExternalAccessAudit audit;

        private NoExternalAccessSecurityManager(ExternalAccessAudit audit) {
            this.audit = audit;
        }

        @Override
        public void checkPermission(java.security.Permission permission) {
            // This observer is scoped only to external I/O channels.
        }

        @Override
        public void checkRead(String file) {
            if (!audit.allowedRead(file)) {
                audit.record("FILE:" + file);
                throw new SecurityException("external file access rejected by DOCX test observer");
            }
        }

        @Override
        public void checkConnect(String host, int port) {
            audit.record("NETWORK:" + host + ":" + port);
            throw new SecurityException("network access rejected by DOCX test observer");
        }
    }

    public static final class ProjectionProbe {

        private ProjectionProbe() {}

        @SuppressWarnings("removal")
        public static void main(String[] arguments) throws Exception {
            Path packagePath = Path.of(arguments[0]);
            Path fileCanary = Path.of(arguments[1]);
            int port = Integer.parseInt(arguments[2]);
            List<String> literalTargets = List.of(arguments[3], arguments[4], arguments[5]);

            InetAddress.getLoopbackAddress();
            try (Socket ignored = new Socket()) {
                SourceHash.sha256("warm-up".getBytes(StandardCharsets.UTF_8));
            }

            SecurityManager previous = System.getSecurityManager();
            ExternalAccessAudit calibrationAudit = new ExternalAccessAudit(packagePath);
            int blockedCanaries = 0;
            System.setSecurityManager(new NoExternalAccessSecurityManager(calibrationAudit));
            try {
                try {
                    Files.exists(fileCanary);
                } catch (SecurityException expected) {
                    blockedCanaries++;
                }
                try (InputStream ignored = Files.newInputStream(fileCanary)) {
                    ignored.read();
                } catch (SecurityException expected) {
                    blockedCanaries++;
                }
                try {
                    InetAddress.getByName("w1-i06-canary.invalid");
                } catch (SecurityException expected) {
                    blockedCanaries++;
                }
                try (Socket ignored = new Socket("127.0.0.1", port)) {
                    // The observer rejects before connect.
                } catch (SecurityException expected) {
                    blockedCanaries++;
                }
            } finally {
                System.setSecurityManager(previous);
            }
            if (blockedCanaries != 4) {
                throw new AssertionError("OBSERVER_CALIBRATION_FAILED:" + calibrationAudit.attemptSummary());
            }

            ExternalAccessAudit operationAudit = new ExternalAccessAudit(packagePath);
            ImageRelationshipProjector.Projection projection;
            System.setSecurityManager(new NoExternalAccessSecurityManager(operationAudit));
            try (SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath)) {
                projection = new ImageRelationshipProjector().project(
                        safePackage,
                        (sourcePart, sourceElementIndex, anchorKind, rowIndex, columnIndex) ->
                                "block",
                        (sourcePart, relationshipId, mediaType, content, digest) -> {
                            throw new AssertionError("EXTERNAL_MEDIA_SINK_MUST_NOT_BE_CALLED");
                        });
            } finally {
                System.setSecurityManager(previous);
            }
            if (operationAudit.attemptCount() != 0) {
                throw new AssertionError("EXTERNAL_ACCESS_OBSERVED:" + operationAudit.attemptSummary());
            }
            if (projection.images().size() != 3 || projection.revisionDiagnostics().size() != 3) {
                throw new AssertionError("EXTERNAL_PROJECTION_CARDINALITY_INVALID");
            }
            for (int index = 0; index < literalTargets.size(); index++) {
                SourceHash expected = SourceHash.sha256(
                        literalTargets.get(index).getBytes(StandardCharsets.UTF_8));
                var image = projection.images().get(index);
                var diagnostic = projection.revisionDiagnostics().get(index);
                if (image.relationshipMode() != DocxRelationshipClassifier.Mode.EXTERNAL
                        || !expected.equals(image.externalTargetLiteralSha256())
                        || image.externalTargetLiteralSha256()
                                != diagnostic.externalTargetLiteralSha256()
                        || image.mediaRef() != null
                        || image.mediaType() != null
                        || image.byteLength() != null
                        || image.contentSha256() != null
                        || !"EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED"
                                .equals(image.securityDisclosure())) {
                    throw new AssertionError("EXTERNAL_IMAGE_PAYLOAD_INVALID:" + index);
                }
            }
            System.out.println("BLOCKED_CANARIES=" + blockedCanaries);
            System.out.println("OPERATION_ATTEMPTS=" + operationAudit.attemptCount());
            System.out.println("PROJECTED_IMAGES=" + projection.images().size());
            System.out.println("DIAGNOSTICS=" + projection.revisionDiagnostics().size());
            System.out.println("DIGESTS_VERIFIED=" + literalTargets.size());
        }
    }
}
