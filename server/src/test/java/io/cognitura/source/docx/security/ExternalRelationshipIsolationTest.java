package io.cognitura.source.docx.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import io.cognitura.source.domain.SourceHash;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import jdk.jfr.Recording;
import jdk.jfr.consumer.RecordedEvent;
import jdk.jfr.consumer.RecordingFile;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class ExternalRelationshipIsolationTest {

    @TempDir
    Path temporaryDirectory;

    @Test
    void classifiesFileHttpAndUnknownExternalRelationshipsWithoutAccessingTheirTargets()
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
                "word/document.xml", resource("minimal-document.xml"),
                "word/styles.xml", resource("minimal-styles.xml"),
                "word/_rels/document.xml.rels", relationshipXml.getBytes(StandardCharsets.UTF_8));
        Path packagePath = temporaryDirectory.resolve("external.docx");
        Files.write(packagePath, DocxSecurityGateTest.zipBytes(entries));
        Path recordingPath = temporaryDirectory.resolve("external-isolation.jfr");

        try (Recording recording = new Recording()) {
            recording.enable("jdk.FileRead").withThreshold(Duration.ZERO);
            recording.enable("jdk.SocketRead").withThreshold(Duration.ZERO);
            recording.enable("jdk.SocketWrite").withThreshold(Duration.ZERO);
            recording.start();
            try (SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath)) {
                assertThat(safePackage.relationships()).hasSize(3);
                assertExternalDigest(safePackage.relationships().get(0), fileTarget);
                assertExternalDigest(safePackage.relationships().get(1), httpTarget);
                assertExternalDigest(safePackage.relationships().get(2), dnsTarget);
                assertThat(safePackage.relationships().toString())
                        .doesNotContain(fileTarget, httpTarget, dnsTarget, "must-not-be-read");
            }
            recording.stop();
            recording.dump(recordingPath);
        } finally {
            server.stop(0);
        }

        assertThat(httpAccessCount).hasValue(0);
        assertThat(Files.readString(fileCanary, StandardCharsets.UTF_8)).isEqualTo("must-not-be-read");
        assertThat(RecordingFile.readAllEvents(recordingPath))
                .allSatisfy(event -> assertExternalTargetWasNotAccessed(event, fileCanary));
    }

    @Test
    void rejectsEveryRequestToDereferenceAnExternalRelationship() throws IOException {
        String target = "file:///must-not-be-opened";
        String relationshipXml = DocxSecurityGateTest.relationships(
                DocxSecurityGateTest.relationship("rExternal", "urn:unknown", target, "External"));
        Path packagePath = temporaryDirectory.resolve("dereference.docx");
        Files.write(packagePath, DocxSecurityGateTest.zipBytes(DocxSecurityGateTest.entries(
                "word/document.xml", resource("minimal-document.xml"),
                "word/styles.xml", resource("minimal-styles.xml"),
                "word/_rels/document.xml.rels", relationshipXml.getBytes(StandardCharsets.UTF_8))));

        try (SafeDocxPackage safePackage = new DocxSecurityGate().open(packagePath)) {
            var external = safePackage.relationships().getFirst();
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

    private static void assertExternalTargetWasNotAccessed(RecordedEvent event, Path fileCanary) {
        if (event.getEventType().getName().equals("jdk.FileRead")) {
            assertThat(event.getString("path")).isNotEqualTo(fileCanary.toString());
        }
        assertThat(event.getEventType().getName())
                .isNotIn("jdk.SocketRead", "jdk.SocketWrite");
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
}
