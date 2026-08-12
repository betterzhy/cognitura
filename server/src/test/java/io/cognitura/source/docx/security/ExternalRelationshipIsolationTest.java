package io.cognitura.source.docx.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import io.cognitura.source.domain.SourceHash;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class ExternalRelationshipIsolationTest {

    @TempDir
    Path temporaryDirectory;

    @Test
    void classifiesFileHttpAndUnknownExternalRelationshipsWithoutStatDnsFileOrNetworkAccess()
            throws Exception {
        AtomicInteger httpAccessCount = new AtomicInteger();
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/canary", exchange -> {
            httpAccessCount.incrementAndGet();
            exchange.sendResponseHeaders(204, -1);
            exchange.close();
        });
        server.start();

        Path fileCanary = temporaryDirectory.resolve("external-secret.txt");
        Files.writeString(fileCanary, "must-not-be-read", StandardCharsets.UTF_8);
        String fileTarget = fileCanary.toUri().toString();
        String httpTarget = "http://127.0.0.1:" + server.getAddress().getPort() + "/canary";
        String dnsTarget = "https://w1-i03-canary.invalid/resource";
        String relationshipXml = DocxSecurityGateTest.relationships(
                DocxSecurityGateTest.relationship("rFile", "urn:unknown:file", fileTarget, "External"),
                DocxSecurityGateTest.relationship("rHttp", "urn:unknown:http", httpTarget, "External"),
                DocxSecurityGateTest.relationship("rDns", "urn:unknown:dns", dnsTarget, "External"));
        LinkedHashMap<String, byte[]> entries = DocxSecurityGateTest.entries(
                "[Content_Types].xml", resource("minimal-content-types.xml"),
                "_rels/.rels", resource("root-office-document.xml.rels"),
                "word/document.xml", resource("minimal-document.xml"),
                "word/styles.xml", resource("minimal-styles.xml"),
                "word/_rels/document.xml.rels", relationshipXml.getBytes(StandardCharsets.UTF_8));
        Path packagePath = temporaryDirectory.resolve("external.docx");
        Files.write(packagePath, DocxSecurityGateTest.zipBytes(entries));

        Path javaExecutable = Path.of(System.getProperty("java.home"), "bin", "java");
        Process process = new ProcessBuilder(
                        javaExecutable.toString(),
                        "-Djava.security.manager=allow",
                        "-cp",
                        System.getProperty("java.class.path"),
                        IsolationProbe.class.getName(),
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
        String probeOutput = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        server.stop(0);

        assertThat(finished).as(probeOutput).isTrue();
        assertThat(process.exitValue()).as(probeOutput).isZero();
        assertThat(probeOutput)
                .contains(
                        "BLOCKED_CANARIES=4",
                        "OPERATION_ATTEMPTS=0",
                        "EXTERNAL_RELATIONSHIPS=3",
                        "DIGESTS_VERIFIED=3");
        assertThat(httpAccessCount).hasValue(0);
        assertThat(Files.readString(fileCanary, StandardCharsets.UTF_8)).isEqualTo("must-not-be-read");
    }

    @Test
    void rejectsEveryRequestToDereferenceAnExternalRelationship() throws IOException {
        String target = "file:///must-not-be-opened";
        String relationshipXml = DocxSecurityGateTest.relationships(
                DocxSecurityGateTest.relationship("rExternal", "urn:unknown", target, "External"));
        Path packagePath = temporaryDirectory.resolve("dereference.docx");
        Files.write(packagePath, DocxSecurityGateTest.zipBytes(DocxSecurityGateTest.entries(
                "[Content_Types].xml", resource("minimal-content-types.xml"),
                "_rels/.rels", resource("root-office-document.xml.rels"),
                "word/document.xml", resource("minimal-document.xml"),
                "word/styles.xml", resource("minimal-styles.xml"),
                "word/_rels/document.xml.rels", relationshipXml.getBytes(StandardCharsets.UTF_8))));

        try (SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath)) {
            var external = safePackage.relationships().stream()
                    .filter(relationship -> relationship.relationshipId().equals("rExternal"))
                    .findFirst()
                    .orElseThrow();
            assertExternalDigest(external, target);
            assertThatThrownBy(() -> safePackage.readRelationshipTarget(external))
                    .isInstanceOf(DocxSecurityViolation.class)
                    .satisfies(error -> assertThat(((DocxSecurityViolation) error).rule())
                            .isEqualTo(DocxSecurityViolation.Rule.EXTERNAL_RELATIONSHIP_DEREFERENCE_REQUEST));
        }
    }

    private static void assertExternalDigest(
            DocxRelationshipClassifier.RelationshipMetadata metadata, String literalTarget) {
        assertThat(metadata.mode()).isEqualTo(DocxRelationshipClassifier.Mode.EXTERNAL);
        assertThat(metadata.internalTargetPart()).isEmpty();
        assertThat(metadata.externalTargetLiteralSha256())
                .contains(SourceHash.sha256(literalTarget.getBytes(StandardCharsets.UTF_8)));
        assertThat(metadata.securityDisclosure())
                .contains("EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED");
    }

    private static byte[] resource(String name) {
        try (var input = ExternalRelationshipIsolationTest.class.getResourceAsStream(
                "/docx/security/" + name)) {
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
            this.runtimeClasspath = java.util.Arrays.stream(
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

        private record RuntimePath(Path path, boolean directory) {
        }
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

    public static final class IsolationProbe {

        private IsolationProbe() {
        }

        @SuppressWarnings("removal")
        public static void main(String[] arguments) throws Exception {
            Path packagePath = Path.of(arguments[0]);
            Path fileCanary = Path.of(arguments[1]);
            int port = Integer.parseInt(arguments[2]);
            List<String> literalTargets = List.of(arguments[3], arguments[4], arguments[5]);

            // Warm all code paths using only the package itself and runtime classpath.
            InetAddress.getLoopbackAddress();
            try (Socket ignored = new Socket()) {
                SourceHash.sha256("warm-up".getBytes(StandardCharsets.UTF_8));
            }

            SecurityManager previous = System.getSecurityManager();
            ExternalAccessAudit probeAudit = new ExternalAccessAudit(packagePath);
            int blockedCanaries = 0;
            System.setSecurityManager(new NoExternalAccessSecurityManager(probeAudit));
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
                    InetAddress.getByName("w1-i03-canary.invalid");
                } catch (SecurityException expected) {
                    blockedCanaries++;
                }
                try (Socket ignored = new Socket("127.0.0.1", port)) {
                    // The observer must reject before connect.
                } catch (SecurityException expected) {
                    blockedCanaries++;
                }
            } finally {
                System.setSecurityManager(previous);
            }
            if (blockedCanaries != 4
                    || !probeAudit.attemptSummary().contains("FILE:" + fileCanary)
                    || !probeAudit.attemptSummary().contains("NETWORK:w1-i03-canary.invalid:-1")
                    || !probeAudit.attemptSummary().contains("NETWORK:127.0.0.1:")) {
                throw new AssertionError("OBSERVER_CALIBRATION_FAILED:" + probeAudit.attemptSummary());
            }

            ExternalAccessAudit operationAudit = new ExternalAccessAudit(packagePath);
            List<DocxRelationshipClassifier.RelationshipMetadata> externalRelationships;
            System.setSecurityManager(new NoExternalAccessSecurityManager(operationAudit));
            try (SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath)) {
                externalRelationships = safePackage.relationships().stream()
                        .filter(relationship -> relationship.mode()
                                == DocxRelationshipClassifier.Mode.EXTERNAL)
                        .toList();
            } finally {
                System.setSecurityManager(previous);
            }
            if (operationAudit.attemptCount() != 0) {
                throw new AssertionError("EXTERNAL_ACCESS_OBSERVED:" + operationAudit.attemptSummary());
            }
            if (externalRelationships.size() != 3) {
                throw new AssertionError("EXTERNAL_RELATIONSHIP_COUNT:" + externalRelationships.size());
            }
            for (int index = 0; index < literalTargets.size(); index++) {
                SourceHash expectedDigest = SourceHash.sha256(
                        literalTargets.get(index).getBytes(StandardCharsets.UTF_8));
                if (!externalRelationships.get(index)
                        .externalTargetLiteralSha256()
                        .orElseThrow()
                        .equals(expectedDigest)) {
                    throw new AssertionError("EXTERNAL_TARGET_DIGEST_MISMATCH:" + index);
                }
            }
            String metadata = externalRelationships.toString();
            if (literalTargets.stream().anyMatch(metadata::contains)) {
                throw new AssertionError("EXTERNAL_TARGET_LITERAL_LEAK");
            }
            System.out.println("BLOCKED_CANARIES=" + blockedCanaries);
            System.out.println("OPERATION_ATTEMPTS=" + operationAudit.attemptCount());
            System.out.println("EXTERNAL_RELATIONSHIPS=" + externalRelationships.size());
            System.out.println("DIGESTS_VERIFIED=" + literalTargets.size());
        }
    }
}
