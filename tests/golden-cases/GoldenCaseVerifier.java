import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public final class GoldenCaseVerifier {
  private static final String W_NS =
      "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
  private static final String R_NS =
      "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
  private static final String PACKAGE_REL_NS =
      "http://schemas.openxmlformats.org/package/2006/relationships";
  private static final String IMAGE_REL_SUFFIX = "/image";
  private static final int MAX_ZIP_ENTRY_COUNT = 4096;
  private static final long MAX_ZIP_ENTRY_BYTES = 16L * 1024L * 1024L;
  private static final long MAX_ZIP_TOTAL_BYTES = 128L * 1024L * 1024L;
  private static final long MAX_COMPRESSION_RATIO = 200L;
  private static final Set<String> REQUIRED_DOCX_ENTRIES = Set.of(
      "word/document.xml",
      "word/styles.xml",
      "word/_rels/document.xml.rels"
  );
  private static final List<String> CASE_IDS = List.of(
      "GC-MYSQL-001",
      "GC-REDIS-001",
      "GC-ENGLISH-001"
  );
  private static final Set<String> EXPECTED_KEYS = Set.of(
      "ExpectedVersion",
      "CaseId",
      "SourceId",
      "SourcePath",
      "SourceSha256",
      "FormalEvidence",
      "MustInclude",
      "MustMergeTarget",
      "MustMergeMembers",
      "MustNotSplit",
      "MustNotPromote",
      "MustNotPromoteMode",
      "ExpectedRoleStatus",
      "ExpectedRole",
      "ExpectedSpineStatus",
      "ExpectedSpine",
      "ExpectedThemeClosureStatus",
      "ExpectedThemeClosure",
      "KnownSourceGaps",
      "ExternalRelationshipPolicy",
      "ParagraphCount",
      "HeadingCount",
      "TableCount",
      "TableRowCount",
      "TableCellCount",
      "ImageReferenceCount",
      "MediaEntryCount",
      "ExternalRelationshipCount",
      "ExternalRelationshipSha256",
      "PageBreakCount",
      "PageOrderSha256",
      "HeadingOrderSha256",
      "BlockOrderSha256",
      "TableStructureSha256",
      "ImageReferenceSha256"
  );
  private static final Set<String> RESULT_KEYS = Set.of(
      "ResultVersion",
      "CaseId",
      "IncludedConcepts",
      "MergeTarget",
      "MergeMembers",
      "StandaloneModules",
      "PromotedModules",
      "Role",
      "Spine",
      "ThemeClosure",
      "ReportedSourceGaps"
  );
  private static final Map<String, AssertionPolicy> POLICIES = policies();

  private GoldenCaseVerifier() {
  }

  public static void main(String[] args) {
    try {
      if (args.length == 2 && "--inspect-docx".equals(args[0])) {
        printStructure(inspectDocx(Path.of(args[1])));
        return;
      }
      if (args.length == 3 && "--probe-file-access".equals(args[0])) {
        inspectDocx(Path.of(args[1]), Path.of(args[2]));
        throw failure(
            "EXTERNAL_ACCESS_GUARD_INACTIVE",
            args[2]
        );
      }
      if (
          args.length == 5 &&
          "--assert-result".equals(args[0]) &&
          "--expected".equals(args[1]) &&
          "--result".equals(args[3])
      ) {
        assertResult(
            Path.of(args[2]).toAbsolutePath().normalize(),
            Path.of(args[4]).toAbsolutePath().normalize(),
            true
        );
        return;
      }
      Path manifest = parseManifestArgument(args);
      validate(manifest);
    } catch (ValidationFailure error) {
      System.err.println("GoldenCaseValidation = FAIL");
      System.err.println(error.code() + ": " + error.getMessage());
      System.exit(1);
    } catch (Exception error) {
      System.err.println("GoldenCaseValidation = FAIL");
      System.err.println("UNCLASSIFIED_VALIDATION_FAILURE: " + error.getMessage());
      System.exit(1);
    }
  }

  private static Path parseManifestArgument(String[] args) {
    if (args.length != 2 || !"--manifest".equals(args[0])) {
      throw failure("USAGE", "expected --manifest <path>");
    }
    return Path.of(args[1]).toAbsolutePath().normalize();
  }

  private static void validate(Path manifestPath) throws Exception {
    Map<String, String> manifest = readFlatYaml(manifestPath);
    requireValue(manifest, "ManifestVersion", "1", "MANIFEST_CONTRACT");
    requireValue(
        manifest,
        "CanonicalProjectName",
        "Cognitura",
        "MANIFEST_CONTRACT"
    );
    requireValue(
        manifest,
        "SourceManifestPath",
        "docs/engineering/cognitura-source-manifest.yaml",
        "MANIFEST_CONTRACT"
    );

    List<String> caseOrder = splitList(required(manifest, "CaseOrder"));
    if (caseOrder.size() != new LinkedHashSet<>(caseOrder).size()) {
      throw failure("DUPLICATE_CASE_ID", String.join("|", caseOrder));
    }
    if (!caseOrder.equals(CASE_IDS)) {
      throw failure(
          "CASE_SET_MISMATCH",
          "expected " + String.join("|", CASE_IDS)
      );
    }
    assertManifestKeys(manifest, caseOrder);

    Path repositoryRoot = repositoryRootFor(manifestPath);
    Path sourceManifestPath = safeResolve(
        repositoryRoot,
        required(manifest, "SourceManifestPath"),
        "SOURCE_MANIFEST_PATH"
    );
    Map<String, SourceRecord> sourceRecords = readSourceManifest(
        sourceManifestPath
    );
    Map<Path, String> beforeHashes = new LinkedHashMap<>();
    int assertionGroupCount = 0;
    int structureCount = 0;
    int externalLinksObserved = 0;
    int externalLinksAccessed = 0;

    for (String caseId : caseOrder) {
      AssertionPolicy policy = POLICIES.get(caseId);
      if (policy == null) {
        throw failure("UNKNOWN_CASE_ID", caseId);
      }
      String prefix = caseId + ".";
      String sourceId = required(manifest, prefix + "SourceId");
      String sourcePath = required(manifest, prefix + "SourcePath");
      String sourceSha256 = required(manifest, prefix + "SourceSha256");
      String expectedPath = required(manifest, prefix + "ExpectedPath");
      String contractResultPath = required(
          manifest,
          prefix + "ContractResultPath"
      );

      if (!sourceId.equals(caseId)) {
        throw failure("SOURCE_ID_MISMATCH", caseId);
      }
      if (!sourcePath.equals(policy.sourcePath())) {
        throw failure("SOURCE_PATH_MISMATCH", caseId);
      }
      if (!expectedPath.equals(policy.expectedPath())) {
        throw failure("EXPECTED_PATH_MISMATCH", caseId);
      }
      if (!contractResultPath.equals(policy.contractResultPath())) {
        throw failure("CONTRACT_RESULT_PATH_MISMATCH", caseId);
      }

      SourceRecord sourceRecord = sourceRecords.get(sourceId);
      if (
          sourceRecord == null ||
          !sourceRecord.caseId().equals(caseId) ||
          !sourceRecord.path().equals(sourcePath) ||
          !"GOLDEN_CASE_ORIGINAL".equals(sourceRecord.role()) ||
          !"ORIGINAL".equals(sourceRecord.version()) ||
          !sourceRecord.sha256().equals(sourceSha256)
      ) {
        throw failure(
            "SOURCE_MANIFEST_BINDING_MISMATCH",
            caseId
        );
      }

      Path source = safeResolve(repositoryRoot, sourcePath, "SOURCE_PATH");
      Path rawRoot = repositoryRoot.resolve("raw").normalize();
      if (!source.startsWith(rawRoot) || !Files.isRegularFile(source)) {
        throw failure("SOURCE_PATH", sourcePath);
      }
      String actualHash = sha256(source);
      if (!actualHash.equals(sourceSha256)) {
        throw failure(
            "HASH_MISMATCH",
            caseId + " expected " + sourceSha256 + ", found " + actualHash
        );
      }
      beforeHashes.put(source, actualHash);

      Path expectedFile = safeResolve(
          repositoryRoot,
          expectedPath,
          "EXPECTED_PATH"
      );
      Map<String, String> expected = readFlatYaml(expectedFile);
      validateExpectedMetadata(
          expected,
          caseId,
          sourceId,
          sourcePath,
          sourceSha256
      );
      validateAssertionPolicy(expected, policy);
      Structure structure = inspectDocx(source);
      if (structure.externalAccessAttemptCount() != 0) {
        throw failure("EXTERNAL_LINK_ACCESS", caseId);
      }
      validateStructure(expected, structure, caseId);
      validateSourceTerms(expected, structure.allText(), caseId);
      Path contractResult = safeResolve(
          repositoryRoot,
          contractResultPath,
          "CONTRACT_RESULT_PATH"
      );
      assertResult(expected, readFlatYaml(contractResult), policy, false);

      assertionGroupCount += 8;
      structureCount += 1;
      externalLinksObserved += structure.externalRelationshipCount();
      externalLinksAccessed += structure.externalAccessAttemptCount();
    }

    for (Map.Entry<Path, String> entry : beforeHashes.entrySet()) {
      String afterHash = sha256(entry.getKey());
      if (!afterHash.equals(entry.getValue())) {
        throw failure(
            "FORMAL_INPUT_MUTATED",
            entry.getKey().toString()
        );
      }
    }

    System.out.println("GoldenCaseRegression = PASS");
    System.out.println("CaseCount = " + caseOrder.size());
    System.out.println(
        "ExecutableAssertionGroupCount = " + assertionGroupCount
    );
    System.out.println("StructuralBaselineCount = " + structureCount);
    System.out.println("ExternalLinksObserved = " + externalLinksObserved);
    System.out.println("ExternalLinksAccessed = " + externalLinksAccessed);
    System.out.println("ExternalAccessGuard = ACTIVE");
    System.out.println("FormalInputsUnchanged = PASS");
    System.out.println("W0-G4 GoldenCaseRegression = PASS");
  }

  private static void assertManifestKeys(
      Map<String, String> manifest,
      List<String> caseOrder
  ) {
    Set<String> expectedKeys = new LinkedHashSet<>(List.of(
        "ManifestVersion",
        "CanonicalProjectName",
        "SourceManifestPath",
        "CaseOrder"
    ));
    for (String caseId : caseOrder) {
      expectedKeys.add(caseId + ".SourceId");
      expectedKeys.add(caseId + ".SourcePath");
      expectedKeys.add(caseId + ".SourceSha256");
      expectedKeys.add(caseId + ".ExpectedPath");
      expectedKeys.add(caseId + ".ContractResultPath");
    }
    if (!manifest.keySet().equals(expectedKeys)) {
      throw failure(
          "MANIFEST_FIELD_SET",
          "unexpected or missing manifest field"
      );
    }
  }

  private static Path repositoryRootFor(Path manifestPath) {
    Path goldenCases = manifestPath.getParent();
    if (
        goldenCases == null ||
        goldenCases.getParent() == null ||
        goldenCases.getParent().getParent() == null
    ) {
      throw failure("MANIFEST_PATH", manifestPath.toString());
    }
    Path root = goldenCases.getParent().getParent().toAbsolutePath().normalize();
    Path expectedManifest = root
        .resolve("test-data/golden-cases/manifest.yaml")
        .normalize();
    if (!manifestPath.equals(expectedManifest)) {
      throw failure(
          "MANIFEST_PATH",
          "manifest must be test-data/golden-cases/manifest.yaml"
      );
    }
    return root;
  }

  private static Path safeResolve(
      Path root,
      String relativePath,
      String code
  ) {
    Path relative = Path.of(relativePath);
    if (relative.isAbsolute()) {
      throw failure(code, relativePath);
    }
    Path resolved = root.resolve(relative).normalize();
    if (!resolved.startsWith(root)) {
      throw failure(code, relativePath);
    }
    if (Files.exists(resolved)) {
      try {
        Path rootReal = root.toRealPath();
        Path resolvedReal = resolved.toRealPath();
        if (!resolvedReal.startsWith(rootReal)) {
          throw failure(code + "_REALPATH", relativePath);
        }
      } catch (IOException error) {
        throw failure(
            code + "_REALPATH",
            relativePath + ": " + error.getMessage()
        );
      }
    }
    return resolved;
  }

  private static Map<String, String> readFlatYaml(Path path) {
    if (!Files.isRegularFile(path)) {
      throw failure("MISSING_FILE", path.toString());
    }
    LinkedHashMap<String, String> values = new LinkedHashMap<>();
    List<String> lines;
    try {
      lines = Files.readAllLines(path, StandardCharsets.UTF_8);
    } catch (IOException error) {
      throw failure("READ_FAILURE", path + ": " + error.getMessage());
    }
    for (int index = 0; index < lines.size(); index++) {
      String line = lines.get(index);
      if (line.isBlank() || line.startsWith("#")) {
        continue;
      }
      int delimiter = line.indexOf(": ");
      if (
          delimiter < 1 ||
          line.startsWith(" ") ||
          line.endsWith(": ") ||
          line.indexOf(": ", delimiter + 2) >= 0
      ) {
        throw failure(
            "YAML_CONTRACT",
            path + ":" + (index + 1)
        );
      }
      String key = line.substring(0, delimiter);
      String value = line.substring(delimiter + 2);
      if (!key.matches("[A-Za-z0-9.-]+") || value.isBlank()) {
        throw failure(
            "YAML_CONTRACT",
            path + ":" + (index + 1)
        );
      }
      if (values.putIfAbsent(key, value) != null) {
        throw failure("DUPLICATE_YAML_KEY", key);
      }
    }
    return values;
  }

  private static Map<String, SourceRecord> readSourceManifest(Path path) {
    if (!Files.isRegularFile(path)) {
      throw failure("MISSING_SOURCE_MANIFEST", path.toString());
    }
    List<String> lines;
    try {
      lines = Files.readAllLines(path, StandardCharsets.UTF_8);
    } catch (IOException error) {
      throw failure("READ_FAILURE", path + ": " + error.getMessage());
    }
    LinkedHashMap<String, SourceRecord> records = new LinkedHashMap<>();
    LinkedHashMap<String, String> current = null;
    for (String line : lines) {
      if (line.startsWith("  - sourceId: ")) {
        if (current != null) {
          addSourceRecord(records, current);
        }
        current = new LinkedHashMap<>();
        current.put("sourceId", line.substring("  - sourceId: ".length()));
      } else if (current != null && line.startsWith("    ")) {
        int delimiter = line.indexOf(": ");
        if (delimiter > 4) {
          current.put(
              line.substring(4, delimiter),
              line.substring(delimiter + 2)
          );
        }
      }
    }
    if (current != null) {
      addSourceRecord(records, current);
    }
    return records;
  }

  private static void addSourceRecord(
      Map<String, SourceRecord> records,
      Map<String, String> raw
  ) {
    String sourceId = raw.get("sourceId");
    if (sourceId == null || records.containsKey(sourceId)) {
      throw failure("SOURCE_MANIFEST_CONTRACT", String.valueOf(sourceId));
    }
    SourceRecord record = new SourceRecord(
        sourceId,
        raw.get("caseId"),
        raw.get("path"),
        raw.get("role"),
        raw.get("version"),
        raw.get("sha256")
    );
    if (
        record.caseId() == null ||
        record.path() == null ||
        record.role() == null ||
        record.version() == null ||
        record.sha256() == null
    ) {
      throw failure("SOURCE_MANIFEST_CONTRACT", sourceId);
    }
    records.put(sourceId, record);
  }

  private static void validateExpectedMetadata(
      Map<String, String> expected,
      String caseId,
      String sourceId,
      String sourcePath,
      String sourceSha256
  ) {
    if (!expected.keySet().equals(EXPECTED_KEYS)) {
      throw failure(
          "EXPECTED_FIELD_SET",
          caseId + " has unexpected or missing fields"
      );
    }
    requireValue(expected, "ExpectedVersion", "1", "EXPECTED_METADATA");
    requireValue(expected, "CaseId", caseId, "EXPECTED_METADATA");
    requireValue(expected, "SourceId", sourceId, "EXPECTED_METADATA");
    requireValue(expected, "SourcePath", sourcePath, "EXPECTED_METADATA");
    requireValue(
        expected,
        "SourceSha256",
        sourceSha256,
        "EXPECTED_METADATA"
    );
  }

  private static void assertResult(
      Path expectedPath,
      Path resultPath,
      boolean emit
  ) {
    Map<String, String> expected = readFlatYaml(expectedPath);
    String caseId = required(expected, "CaseId");
    AssertionPolicy policy = POLICIES.get(caseId);
    if (policy == null) {
      throw failure("UNKNOWN_CASE_ID", caseId);
    }
    validateExpectedMetadata(
        expected,
        caseId,
        caseId,
        policy.sourcePath(),
        required(expected, "SourceSha256")
    );
    validateAssertionPolicy(expected, policy);
    assertResult(
        expected,
        readFlatYaml(resultPath),
        policy,
        emit
    );
  }

  private static void assertResult(
      Map<String, String> expected,
      Map<String, String> result,
      AssertionPolicy policy,
      boolean emit
  ) {
    if (!result.keySet().equals(RESULT_KEYS)) {
      throw failure(
          "RESULT_FIELD_SET",
          "unexpected or missing result fields"
      );
    }
    requireValue(result, "ResultVersion", "1", "RESULT_METADATA");
    String caseId = required(expected, "CaseId");
    requireValue(result, "CaseId", caseId, "RESULT_METADATA");

    Set<String> included = valueSet(result, "IncludedConcepts");
    if (!included.containsAll(valueSet(expected, "MustInclude"))) {
      throw failure("MUST_INCLUDE_VIOLATION", caseId);
    }

    if (
        !required(result, "MergeTarget").equals(
            required(expected, "MustMergeTarget")
        ) ||
        !valueSet(result, "MergeMembers").equals(
            valueSet(expected, "MustMergeMembers")
        )
    ) {
      throw failure("MUST_MERGE_VIOLATION", caseId);
    }

    Set<String> standalone = optionalValueSet(
        result,
        "StandaloneModules"
    );
    if (
        standalone.stream().anyMatch(
            valueSet(expected, "MustNotSplit")::contains
        )
    ) {
      throw failure("MUST_NOT_SPLIT_VIOLATION", caseId);
    }

    Set<String> promoted = optionalValueSet(result, "PromotedModules");
    Set<String> promotionPolicy = valueSet(expected, "MustNotPromote");
    String promotionMode = required(expected, "MustNotPromoteMode");
    if (
        ("NOT_ALL".equals(promotionMode) &&
            promoted.containsAll(promotionPolicy)) ||
        ("NONE_ALLOWED".equals(promotionMode) &&
            promoted.stream().anyMatch(promotionPolicy::contains))
    ) {
      throw failure("MUST_NOT_PROMOTE_VIOLATION", caseId);
    }
    if (
        !"NOT_ALL".equals(promotionMode) &&
        !"NONE_ALLOWED".equals(promotionMode)
    ) {
      throw failure("ASSERTION_POLICY_MISMATCH", "MustNotPromoteMode");
    }

    assertExpectedValue(
        expected,
        result,
        "ExpectedRoleStatus",
        "ExpectedRole",
        "Role",
        "EXPECTED_ROLE_VIOLATION",
        caseId
    );
    assertExpectedValue(
        expected,
        result,
        "ExpectedSpineStatus",
        "ExpectedSpine",
        "Spine",
        "EXPECTED_SPINE_VIOLATION",
        caseId
    );
    assertExpectedValue(
        expected,
        result,
        "ExpectedThemeClosureStatus",
        "ExpectedThemeClosure",
        "ThemeClosure",
        "EXPECTED_THEME_CLOSURE_VIOLATION",
        caseId
    );

    if (
        !valueSet(result, "ReportedSourceGaps").equals(
            valueSet(expected, "KnownSourceGaps")
        )
    ) {
      throw failure("KNOWN_SOURCE_GAPS_VIOLATION", caseId);
    }

    if (emit) {
      System.out.println("ResultAssertion = PASS");
      System.out.println("CaseId = " + caseId);
      System.out.println("ExecutableAssertionGroupCount = 8");
    }
  }

  private static void assertExpectedValue(
      Map<String, String> expected,
      Map<String, String> result,
      String statusField,
      String expectedField,
      String resultField,
      String code,
      String caseId
  ) {
    String status = required(expected, statusField);
    String expectedValue = required(expected, expectedField);
    String resultValue = required(result, resultField);
    if (
        ("SOURCE_GAP".equals(status) &&
            (!"NOT_ASSERTED".equals(expectedValue) ||
                !"NOT_ASSERTED".equals(resultValue))) ||
        ("ASSERTED".equals(status) &&
            !expectedValue.equals(resultValue)) ||
        (!"SOURCE_GAP".equals(status) && !"ASSERTED".equals(status))
    ) {
      throw failure(code, caseId);
    }
  }

  private static Set<String> valueSet(
      Map<String, String> values,
      String key
  ) {
    return new LinkedHashSet<>(splitList(required(values, key)));
  }

  private static Set<String> optionalValueSet(
      Map<String, String> values,
      String key
  ) {
    String value = required(values, key);
    if ("NONE".equals(value)) {
      return Set.of();
    }
    return new LinkedHashSet<>(splitList(value));
  }

  private static void validateAssertionPolicy(
      Map<String, String> expected,
      AssertionPolicy policy
  ) {
    requireValue(
        expected,
        "FormalEvidence",
        policy.formalEvidence(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "MustInclude",
        policy.mustInclude(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "MustMergeTarget",
        policy.mustMergeTarget(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "MustMergeMembers",
        policy.mustMergeMembers(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "MustNotSplit",
        policy.mustNotSplit(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "MustNotPromote",
        policy.mustNotPromote(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "MustNotPromoteMode",
        policy.mustNotPromoteMode(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "ExpectedRoleStatus",
        "SOURCE_GAP",
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "ExpectedRole",
        "NOT_ASSERTED",
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "ExpectedSpineStatus",
        policy.expectedSpineStatus(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "ExpectedSpine",
        policy.expectedSpine(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "ExpectedThemeClosureStatus",
        "SOURCE_GAP",
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "ExpectedThemeClosure",
        "NOT_ASSERTED",
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "KnownSourceGaps",
        policy.knownSourceGaps(),
        "ASSERTION_POLICY_MISMATCH"
    );
    requireValue(
        expected,
        "ExternalRelationshipPolicy",
        "RECORD_ONLY_DO_NOT_RESOLVE",
        "EXTERNAL_LINK_POLICY"
    );
    for (String field : List.of(
        "MustInclude",
        "MustMergeMembers",
        "MustNotSplit",
        "MustNotPromote",
        "ExpectedSpine",
        "KnownSourceGaps"
    )) {
      List<String> values = splitList(required(expected, field));
      if (values.size() != new LinkedHashSet<>(values).size()) {
        throw failure("DUPLICATE_ASSERTION", field);
      }
    }
  }

  private static void validateSourceTerms(
      Map<String, String> expected,
      String allText,
      String caseId
  ) {
    String comparable = allText.toLowerCase(Locale.ROOT);
    for (String term : splitList(required(expected, "MustInclude"))) {
      if (!comparable.contains(term.toLowerCase(Locale.ROOT))) {
        throw failure(
            "SOURCE_TERM_MISSING",
            caseId + " -> " + term
        );
      }
    }
  }

  private static void validateStructure(
      Map<String, String> expected,
      Structure actual,
      String caseId
  ) {
    requireInt(
        expected,
        "HeadingCount",
        actual.headingCount(),
        "HEADING_ORDER_MISMATCH",
        caseId
    );
    requireValue(
        expected,
        "HeadingOrderSha256",
        actual.headingOrderSha256(),
        "HEADING_ORDER_MISMATCH"
    );
    for (Map.Entry<String, Integer> check : Map.of(
        "TableCount", actual.tableCount(),
        "TableRowCount", actual.tableRowCount(),
        "TableCellCount", actual.tableCellCount()
    ).entrySet()) {
      requireInt(
          expected,
          check.getKey(),
          check.getValue(),
          "TABLE_STRUCTURE_MISMATCH",
          caseId
      );
    }
    requireValue(
        expected,
        "TableStructureSha256",
        actual.tableStructureSha256(),
        "TABLE_STRUCTURE_MISMATCH"
    );
    for (Map.Entry<String, Integer> check : Map.of(
        "ImageReferenceCount", actual.imageReferenceCount(),
        "MediaEntryCount", actual.mediaEntryCount()
    ).entrySet()) {
      requireInt(
          expected,
          check.getKey(),
          check.getValue(),
          "IMAGE_REFERENCE_MISMATCH",
          caseId
      );
    }
    requireValue(
        expected,
        "ImageReferenceSha256",
        actual.imageReferenceSha256(),
        "IMAGE_REFERENCE_MISMATCH"
    );
    requireInt(
        expected,
        "ExternalRelationshipCount",
        actual.externalRelationshipCount(),
        "EXTERNAL_RELATIONSHIP_MISMATCH",
        caseId
    );
    requireValue(
        expected,
        "ExternalRelationshipSha256",
        actual.externalRelationshipSha256(),
        "EXTERNAL_RELATIONSHIP_MISMATCH"
    );
    requireInt(
        expected,
        "ParagraphCount",
        actual.paragraphCount(),
        "BLOCK_ORDER_MISMATCH",
        caseId
    );
    requireInt(
        expected,
        "PageBreakCount",
        actual.pageBreakCount(),
        "PAGE_OR_ORDER_MISMATCH",
        caseId
    );
    requireValue(
        expected,
        "PageOrderSha256",
        actual.pageOrderSha256(),
        "PAGE_OR_ORDER_MISMATCH"
    );
    requireValue(
        expected,
        "BlockOrderSha256",
        actual.blockOrderSha256(),
        "BLOCK_ORDER_MISMATCH"
    );
  }

  private static void requireInt(
      Map<String, String> values,
      String key,
      int actual,
      String code,
      String caseId
  ) {
    String expected = required(values, key);
    if (!expected.equals(Integer.toString(actual))) {
      throw failure(
          code,
          caseId + " " + key + " expected " + expected + ", found " + actual
      );
    }
  }

  private static void requireValue(
      Map<String, String> values,
      String key,
      String expected,
      String code
  ) {
    String actual = required(values, key);
    if (!actual.equals(expected)) {
      throw failure(
          code,
          key + " expected '" + expected + "', found '" + actual + "'"
      );
    }
  }

  private static String required(Map<String, String> values, String key) {
    String value = values.get(key);
    if (value == null || value.isBlank()) {
      throw failure("MISSING_FIELD", key);
    }
    return value;
  }

  private static List<String> splitList(String value) {
    List<String> items = Arrays.stream(value.split("\\|", -1))
        .map(String::trim)
        .toList();
    if (items.isEmpty() || items.stream().anyMatch(String::isBlank)) {
      throw failure("EMPTY_ASSERTION_ITEM", value);
    }
    return items;
  }

  @SuppressWarnings("removal")
  static Structure inspectDocx(Path path) {
    return inspectDocx(path, null);
  }

  @SuppressWarnings("removal")
  private static Structure inspectDocx(Path path, Path accessProbe) {
    Path allowedSource = path.toAbsolutePath().normalize();
    ExternalAccessAudit accessAudit = new ExternalAccessAudit(allowedSource);
    SecurityManager previousSecurityManager = System.getSecurityManager();
    System.setSecurityManager(
        new NoExternalAccessSecurityManager(accessAudit)
    );
    try (ZipFile zip = new ZipFile(path.toFile(), StandardCharsets.UTF_8)) {
      if (accessProbe != null) {
        try (InputStream ignored = Files.newInputStream(accessProbe)) {
          ignored.read();
        }
      }
      validateZipInventory(zip);
      Document document = parseXml(readEntry(zip, "word/document.xml"));
      Document stylesDocument = parseXml(readEntry(zip, "word/styles.xml"));
      Document relationshipsDocument = parseXml(
          readEntry(zip, "word/_rels/document.xml.rels")
      );
      Map<String, String> styleNames = readStyleNames(stylesDocument);
      Map<String, Relationship> relationships = readRelationships(
          relationshipsDocument
      );
      Set<String> imageRelationshipIds = new HashSet<>();
      int externalRelationships = 0;
      StringBuilder externalRelationshipRecord = new StringBuilder();
      for (Relationship relationship : relationships.values()) {
        if (relationship.type().endsWith(IMAGE_REL_SUFFIX)) {
          imageRelationshipIds.add(relationship.id());
        }
        if (relationship.external()) {
          externalRelationships += 1;
          addRecord(
              externalRelationshipRecord,
              relationship.id(),
              relationship.type(),
              relationship.target()
          );
        }
      }

      Element body = firstElement(document, W_NS, "body");
      StringBuilder headings = new StringBuilder();
      StringBuilder blocks = new StringBuilder();
      StringBuilder tables = new StringBuilder();
      StringBuilder allText = new StringBuilder();
      int paragraphCount = 0;
      int headingCount = 0;
      int tableCount = 0;
      int tableRowCount = 0;
      int tableCellCount = 0;

      for (Node child = body.getFirstChild(); child != null; child = child.getNextSibling()) {
        if (!(child instanceof Element element)) {
          continue;
        }
        if (W_NS.equals(element.getNamespaceURI()) && "p".equals(element.getLocalName())) {
          paragraphCount += 1;
          String paragraphText = elementText(element);
          String styleName = paragraphStyleName(element, styleNames);
          addRecord(blocks, "P", styleName, paragraphText);
          addText(allText, paragraphText);
          if (isHeading(styleName)) {
            headingCount += 1;
            addRecord(headings, styleName, paragraphText);
          }
        } else if (
            W_NS.equals(element.getNamespaceURI()) &&
            "tbl".equals(element.getLocalName())
        ) {
          tableCount += 1;
          StringBuilder tableRecord = new StringBuilder();
          int rowIndex = 0;
          for (Element row : directChildren(element, W_NS, "tr")) {
            tableRowCount += 1;
            int cellIndex = 0;
            for (Element cell : directChildren(row, W_NS, "tc")) {
              tableCellCount += 1;
              String cellText = elementText(cell);
              addRecord(
                  tableRecord,
                  Integer.toString(rowIndex),
                  Integer.toString(cellIndex),
                  cellText
              );
              addText(allText, cellText);
              cellIndex += 1;
            }
            rowIndex += 1;
          }
          addRecord(
              tables,
              Integer.toString(tableCount - 1),
              tableRecord.toString()
          );
          addRecord(blocks, "T", tableRecord.toString());
        }
      }

      List<String> imageReferences = new ArrayList<>();
      collectImageReferences(
          document.getDocumentElement(),
          imageRelationshipIds,
          relationships,
          imageReferences
      );
      StringBuilder imageReferenceRecord = new StringBuilder();
      for (String imageReference : imageReferences) {
        addRecord(imageReferenceRecord, imageReference);
      }

      int mediaEntryCount = 0;
      for (ZipEntry entry : java.util.Collections.list(zip.entries())) {
        if (
            !entry.isDirectory() &&
            entry.getName().startsWith("word/media/")
        ) {
          mediaEntryCount += 1;
        }
      }

      int pageBreakCount = countPageBreaks(body);
      String pageOrderRecord = pageOrderRecord(body);
      if (accessAudit.attemptCount() != 0) {
        throw failure(
            "EXTERNAL_LINK_ACCESS",
            accessAudit.attemptSummary()
        );
      }
      return new Structure(
          paragraphCount,
          headingCount,
          tableCount,
          tableRowCount,
          tableCellCount,
          imageReferences.size(),
          mediaEntryCount,
          externalRelationships,
          accessAudit.attemptCount(),
          pageBreakCount,
          sha256(
              externalRelationshipRecord
                  .toString()
                  .getBytes(StandardCharsets.UTF_8)
          ),
          sha256(pageOrderRecord.getBytes(StandardCharsets.UTF_8)),
          sha256(headings.toString().getBytes(StandardCharsets.UTF_8)),
          sha256(blocks.toString().getBytes(StandardCharsets.UTF_8)),
          sha256(tables.toString().getBytes(StandardCharsets.UTF_8)),
          sha256(imageReferenceRecord.toString().getBytes(StandardCharsets.UTF_8)),
          allText.toString()
      );
    } catch (SecurityException error) {
      if (accessAudit.attemptCount() != 0) {
        throw failure(
            "EXTERNAL_LINK_ACCESS",
            accessAudit.attemptSummary()
        );
      }
      throw error;
    } catch (IOException error) {
      throw failure("DOCX_READ_FAILURE", path + ": " + error.getMessage());
    } finally {
      System.setSecurityManager(previousSecurityManager);
    }
  }

  private static byte[] readEntry(ZipFile zip, String name) throws IOException {
    ZipEntry entry = zip.getEntry(name);
    if (entry == null) {
      throw failure("DOCX_ENTRY_MISSING", name);
    }
    try (InputStream input = zip.getInputStream(entry)) {
      ByteArrayOutputStream output = new ByteArrayOutputStream();
      byte[] buffer = new byte[8192];
      long total = 0;
      int count;
      while ((count = input.read(buffer)) >= 0) {
        total += count;
        if (total > MAX_ZIP_ENTRY_BYTES) {
          throw failure("DOCX_ENTRY_LIMIT", name);
        }
        output.write(buffer, 0, count);
      }
      return output.toByteArray();
    }
  }

  private static void validateZipInventory(ZipFile zip) {
    Set<String> names = new HashSet<>();
    Map<String, Integer> requiredCounts = new LinkedHashMap<>();
    for (String required : REQUIRED_DOCX_ENTRIES) {
      requiredCounts.put(required, 0);
    }
    long totalBytes = 0;
    int entryCount = 0;
    for (ZipEntry entry : java.util.Collections.list(zip.entries())) {
      entryCount += 1;
      if (entryCount > MAX_ZIP_ENTRY_COUNT) {
        throw failure("DOCX_ENTRY_COUNT_LIMIT", zip.getName());
      }
      if (!names.add(entry.getName())) {
        throw failure("DOCX_DUPLICATE_ENTRY", entry.getName());
      }
      if (requiredCounts.containsKey(entry.getName())) {
        requiredCounts.put(
            entry.getName(),
            requiredCounts.get(entry.getName()) + 1
        );
      }
      if (entry.isDirectory()) {
        continue;
      }
      long size = entry.getSize();
      long compressedSize = entry.getCompressedSize();
      if (size < 0 || compressedSize < 0) {
        throw failure("DOCX_ENTRY_SIZE_UNKNOWN", entry.getName());
      }
      if (size > MAX_ZIP_ENTRY_BYTES) {
        throw failure("DOCX_ENTRY_LIMIT", entry.getName());
      }
      totalBytes += size;
      if (totalBytes > MAX_ZIP_TOTAL_BYTES) {
        throw failure("DOCX_TOTAL_SIZE_LIMIT", zip.getName());
      }
      if (
          size > 0 &&
          (
              compressedSize == 0 ||
              size / Math.max(1, compressedSize) > MAX_COMPRESSION_RATIO
          )
      ) {
        throw failure("DOCX_COMPRESSION_RATIO", entry.getName());
      }
    }
    for (Map.Entry<String, Integer> required : requiredCounts.entrySet()) {
      if (required.getValue() != 1) {
        throw failure(
            "DOCX_REQUIRED_ENTRY_COUNT",
            required.getKey()
        );
      }
    }
  }

  private static Document parseXml(byte[] bytes) {
    try {
      DocumentBuilderFactory factory =
          DocumentBuilderFactory.newDefaultInstance();
      factory.setNamespaceAware(true);
      factory.setXIncludeAware(false);
      factory.setExpandEntityReferences(false);
      factory.setFeature(
          "http://apache.org/xml/features/disallow-doctype-decl",
          true
      );
      factory.setFeature(
          "http://xml.org/sax/features/external-general-entities",
          false
      );
      factory.setFeature(
          "http://xml.org/sax/features/external-parameter-entities",
          false
      );
      factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
      factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
      DocumentBuilder builder = factory.newDocumentBuilder();
      return builder.parse(new ByteArrayInputStream(bytes));
    } catch (Exception error) {
      throw failure("DOCX_XML_INVALID", error.getMessage());
    }
  }

  private static Map<String, String> readStyleNames(Document styles) {
    LinkedHashMap<String, String> names = new LinkedHashMap<>();
    NodeList styleNodes = styles.getElementsByTagNameNS(W_NS, "style");
    for (int index = 0; index < styleNodes.getLength(); index++) {
      Element style = (Element) styleNodes.item(index);
      String styleId = style.getAttributeNS(W_NS, "styleId");
      Element name = firstDirectChild(style, W_NS, "name");
      if (!styleId.isBlank() && name != null) {
        names.put(styleId, name.getAttributeNS(W_NS, "val"));
      }
    }
    return names;
  }

  private static Map<String, Relationship> readRelationships(
      Document relationshipsDocument
  ) {
    LinkedHashMap<String, Relationship> relationships = new LinkedHashMap<>();
    NodeList nodes = relationshipsDocument.getElementsByTagNameNS(
        PACKAGE_REL_NS,
        "Relationship"
    );
    for (int index = 0; index < nodes.getLength(); index++) {
      Element element = (Element) nodes.item(index);
      String id = element.getAttribute("Id");
      Relationship relationship = new Relationship(
          id,
          element.getAttribute("Type"),
          element.getAttribute("Target"),
          "External".equals(element.getAttribute("TargetMode"))
      );
      relationships.put(id, relationship);
    }
    return relationships;
  }

  private static String paragraphStyleName(
      Element paragraph,
      Map<String, String> styleNames
  ) {
    Element properties = firstDirectChild(paragraph, W_NS, "pPr");
    if (properties == null) {
      return "";
    }
    Element style = firstDirectChild(properties, W_NS, "pStyle");
    if (style == null) {
      return "";
    }
    String styleId = style.getAttributeNS(W_NS, "val");
    return styleNames.getOrDefault(styleId, styleId);
  }

  private static boolean isHeading(String styleName) {
    String normalized = styleName.toLowerCase(Locale.ROOT);
    return normalized.startsWith("heading") || normalized.contains("标题");
  }

  private static String elementText(Element element) {
    StringBuilder text = new StringBuilder();
    collectText(element, text);
    return text.toString().strip();
  }

  private static void collectText(Node node, StringBuilder text) {
    if (node instanceof Element element && W_NS.equals(element.getNamespaceURI())) {
      if ("t".equals(element.getLocalName())) {
        text.append(element.getTextContent());
        return;
      }
      if ("tab".equals(element.getLocalName())) {
        text.append('\t');
      } else if ("br".equals(element.getLocalName())) {
        text.append('\n');
      }
    }
    for (Node child = node.getFirstChild(); child != null; child = child.getNextSibling()) {
      collectText(child, text);
    }
  }

  private static void collectImageReferences(
      Node node,
      Set<String> imageRelationshipIds,
      Map<String, Relationship> relationships,
      List<String> references
  ) {
    if (node instanceof Element element) {
      NamedNodeMap attributes = element.getAttributes();
      for (int index = 0; index < attributes.getLength(); index++) {
        Node attribute = attributes.item(index);
        String value = attribute.getNodeValue();
        if (
            R_NS.equals(attribute.getNamespaceURI()) &&
            imageRelationshipIds.contains(value)
        ) {
          Relationship relationship = relationships.get(value);
          references.add(value + "|" + relationship.target());
        }
      }
    }
    for (Node child = node.getFirstChild(); child != null; child = child.getNextSibling()) {
      collectImageReferences(
          child,
          imageRelationshipIds,
          relationships,
          references
      );
    }
  }

  private static int countPageBreaks(Element body) {
    int count = body.getElementsByTagNameNS(W_NS, "lastRenderedPageBreak")
        .getLength();
    NodeList breaks = body.getElementsByTagNameNS(W_NS, "br");
    for (int index = 0; index < breaks.getLength(); index++) {
      Element element = (Element) breaks.item(index);
      if ("page".equals(element.getAttributeNS(W_NS, "type"))) {
        count += 1;
      }
    }
    return count;
  }

  private static String pageOrderRecord(Element body) {
    StringBuilder record = new StringBuilder();
    collectPageMarkers(body, "0", record);
    return record.toString();
  }

  private static void collectPageMarkers(
      Element element,
      String path,
      StringBuilder record
  ) {
    if (
        W_NS.equals(element.getNamespaceURI()) &&
        "lastRenderedPageBreak".equals(element.getLocalName())
    ) {
      addRecord(record, path, "LAST_RENDERED_PAGE_BREAK");
    } else if (
        W_NS.equals(element.getNamespaceURI()) &&
        "br".equals(element.getLocalName()) &&
        "page".equals(element.getAttributeNS(W_NS, "type"))
    ) {
      addRecord(record, path, "EXPLICIT_PAGE_BREAK");
    }

    int elementIndex = 0;
    for (
        Node child = element.getFirstChild();
        child != null;
        child = child.getNextSibling()
    ) {
      if (child instanceof Element childElement) {
        collectPageMarkers(
            childElement,
            path + "." + elementIndex,
            record
        );
        elementIndex += 1;
      }
    }
  }

  private static Element firstElement(
      Document document,
      String namespace,
      String localName
  ) {
    NodeList elements = document.getElementsByTagNameNS(namespace, localName);
    if (elements.getLength() == 0) {
      throw failure("DOCX_XML_CONTRACT", localName);
    }
    return (Element) elements.item(0);
  }

  private static Element firstDirectChild(
      Element parent,
      String namespace,
      String localName
  ) {
    for (Node child = parent.getFirstChild(); child != null; child = child.getNextSibling()) {
      if (
          child instanceof Element element &&
          namespace.equals(element.getNamespaceURI()) &&
          localName.equals(element.getLocalName())
      ) {
        return element;
      }
    }
    return null;
  }

  private static List<Element> directChildren(
      Element parent,
      String namespace,
      String localName
  ) {
    List<Element> children = new ArrayList<>();
    for (Node child = parent.getFirstChild(); child != null; child = child.getNextSibling()) {
      if (
          child instanceof Element element &&
          namespace.equals(element.getNamespaceURI()) &&
          localName.equals(element.getLocalName())
      ) {
        children.add(element);
      }
    }
    return children;
  }

  private static void addText(StringBuilder builder, String value) {
    if (!value.isBlank()) {
      builder.append(value).append('\n');
    }
  }

  private static void addRecord(StringBuilder builder, String... fields) {
    for (String field : fields) {
      builder
          .append(field.length())
          .append(':')
          .append(field)
          .append('|');
    }
    builder.append('\n');
  }

  private static String sha256(Path path) {
    try (InputStream input = Files.newInputStream(path)) {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] buffer = new byte[8192];
      int count;
      while ((count = input.read(buffer)) >= 0) {
        digest.update(buffer, 0, count);
      }
      return hex(digest.digest());
    } catch (IOException | NoSuchAlgorithmException error) {
      throw failure("HASH_FAILURE", path + ": " + error.getMessage());
    }
  }

  private static String sha256(byte[] bytes) {
    try {
      return hex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException error) {
      throw new IllegalStateException(error);
    }
  }

  private static String hex(byte[] bytes) {
    StringBuilder output = new StringBuilder(bytes.length * 2);
    for (byte value : bytes) {
      output.append(String.format("%02x", value));
    }
    return output.toString();
  }

  private static void printStructure(Structure structure) {
    System.out.println("ParagraphCount: " + structure.paragraphCount());
    System.out.println("HeadingCount: " + structure.headingCount());
    System.out.println("TableCount: " + structure.tableCount());
    System.out.println("TableRowCount: " + structure.tableRowCount());
    System.out.println("TableCellCount: " + structure.tableCellCount());
    System.out.println(
        "ImageReferenceCount: " + structure.imageReferenceCount()
    );
    System.out.println("MediaEntryCount: " + structure.mediaEntryCount());
    System.out.println(
        "ExternalRelationshipCount: " +
        structure.externalRelationshipCount()
    );
    System.out.println(
        "ExternalRelationshipSha256: " +
        structure.externalRelationshipSha256()
    );
    System.out.println("PageBreakCount: " + structure.pageBreakCount());
    System.out.println("PageOrderSha256: " + structure.pageOrderSha256());
    System.out.println(
        "HeadingOrderSha256: " + structure.headingOrderSha256()
    );
    System.out.println("BlockOrderSha256: " + structure.blockOrderSha256());
    System.out.println(
        "TableStructureSha256: " + structure.tableStructureSha256()
    );
    System.out.println(
        "ImageReferenceSha256: " + structure.imageReferenceSha256()
    );
  }

  private static Map<String, AssertionPolicy> policies() {
    LinkedHashMap<String, AssertionPolicy> policies = new LinkedHashMap<>();
    policies.put(
        "GC-MYSQL-001",
        new AssertionPolicy(
            "raw/11-MySQL数据库.docx",
            "test-data/golden-cases/mysql.expected.yaml",
            "tests/golden-cases/results/mysql.result.yaml",
            "OD1.2§21.MySQL",
            "锁|事务|数据行|undo log|MVCC|Read View|隐藏列|幻读",
            "事务可见性与幻读控制",
            "锁|事务|数据行|Undo Log",
            "锁|事务|数据行|Undo Log",
            "MVCC|Read View字段|隐藏列|单个锁类型",
            "NOT_ALL",
            "SOURCE_GAP",
            "NOT_ASSERTED",
            "EXPECTED_ROLE_NOT_SPECIFIED|EXPECTED_SPINE_NOT_SPECIFIED|EXPECTED_THEME_CLOSURE_NOT_SPECIFIED"
        )
    );
    policies.put(
        "GC-REDIS-001",
        new AssertionPolicy(
            "raw/12-Redis中间件.docx",
            "test-data/golden-cases/redis.expected.yaml",
            "tests/golden-cases/results/redis.result.yaml",
            "OD1.2§21.Redis",
            "死循环|客户端输出缓冲区|Pending Writes|beforeSleep|写事件|多线程 IO",
            "请求处理与高性能线程模型",
            "事件循环|客户端输出缓冲|Pending Writes|beforeSleep|写事件兜底|IO 多线程边界",
            "事件循环|客户端输出缓冲|Pending Writes|beforeSleep|写事件兜底|IO 多线程边界",
            "beforeSleep",
            "NONE_ALLOWED",
            "SOURCE_GAP",
            "NOT_ASSERTED",
            "EXPECTED_ROLE_NOT_SPECIFIED|EXPECTED_SPINE_NOT_SPECIFIED|EXPECTED_THEME_CLOSURE_NOT_SPECIFIED"
        )
    );
    policies.put(
        "GC-ENGLISH-001",
        new AssertionPolicy(
            "raw/40-英语学习.docx",
            "test-data/golden-cases/english.expected.yaml",
            "tests/golden-cases/results/english.result.yaml",
            "OD1.2§21.英语",
            "主+谓（S+V）|主+系+表|主+谓+宾|主+谓+间宾+直宾|主+谓+宾+宾补|谓语动词|SVOO|SVOC",
            "五大句型统一规则体系",
            "主+谓|主+系+表|主+谓+宾|主+谓+间宾+直宾|主+谓+宾+宾补",
            "主+谓|主+系+表|主+谓+宾|主+谓+间宾+直宾|主+谓+宾+宾补",
            "例句|主导航节点",
            "NONE_ALLOWED",
            "ASSERTED",
            "谓语动词类型|必要成分|五大句型|判定路径|SVOO-SVOC辨析",
            "EXPECTED_ROLE_NOT_SPECIFIED|EXPECTED_THEME_CLOSURE_NOT_SPECIFIED"
        )
    );
    return Map.copyOf(policies);
  }

  private static ValidationFailure failure(String code, String message) {
    return new ValidationFailure(code, message);
  }

  record SourceRecord(
      String sourceId,
      String caseId,
      String path,
      String role,
      String version,
      String sha256
  ) {
  }

  record Relationship(
      String id,
      String type,
      String target,
      boolean external
  ) {
  }

  record AssertionPolicy(
      String sourcePath,
      String expectedPath,
      String contractResultPath,
      String formalEvidence,
      String mustInclude,
      String mustMergeTarget,
      String mustMergeMembers,
      String mustNotSplit,
      String mustNotPromote,
      String mustNotPromoteMode,
      String expectedSpineStatus,
      String expectedSpine,
      String knownSourceGaps
  ) {
  }

  record Structure(
      int paragraphCount,
      int headingCount,
      int tableCount,
      int tableRowCount,
      int tableCellCount,
      int imageReferenceCount,
      int mediaEntryCount,
      int externalRelationshipCount,
      int externalAccessAttemptCount,
      int pageBreakCount,
      String externalRelationshipSha256,
      String pageOrderSha256,
      String headingOrderSha256,
      String blockOrderSha256,
      String tableStructureSha256,
      String imageReferenceSha256,
      String allText
  ) {
  }

  static final class ExternalAccessAudit {
    private final Path allowedSource;
    private final Path javaHome;
    private final List<String> attempts = new ArrayList<>();
    private int attemptCount;

    ExternalAccessAudit(Path allowedSource) {
      this.allowedSource = allowedSource;
      this.javaHome = Path.of(
          System.getProperty("java.home")
      ).toAbsolutePath().normalize();
    }

    boolean allowedRead(String file) {
      if (file == null) {
        return false;
      }
      Path candidate;
      try {
        candidate = Path.of(file).toAbsolutePath().normalize();
      } catch (RuntimeException error) {
        return false;
      }
      return candidate.equals(allowedSource) ||
          candidate.startsWith(javaHome) ||
          candidate.equals(Path.of("/dev/random")) ||
          candidate.equals(Path.of("/dev/urandom"));
    }

    void recordAttempt(String target) {
      attemptCount += 1;
      attempts.add(target);
    }

    int attemptCount() {
      return attemptCount;
    }

    String attemptSummary() {
      return String.join("|", attempts);
    }
  }

  @SuppressWarnings("removal")
  static final class NoExternalAccessSecurityManager
      extends SecurityManager {
    private final ExternalAccessAudit audit;

    NoExternalAccessSecurityManager(ExternalAccessAudit audit) {
      this.audit = audit;
    }

    @Override
    public void checkPermission(java.security.Permission permission) {
      // This guard is scoped only to external I/O observation.
    }

    @Override
    public void checkRead(String file) {
      if (!audit.allowedRead(file)) {
        audit.recordAttempt("FILE:" + file);
        throw new SecurityException(
            "external file access denied by Golden Case verifier: " + file
        );
      }
    }

    @Override
    public void checkConnect(String host, int port) {
      audit.recordAttempt("NETWORK:" + host + ":" + port);
      throw new SecurityException(
          "network access denied by Golden Case verifier"
      );
    }
  }

  static final class ValidationFailure extends RuntimeException {
    private static final long serialVersionUID = 1L;

    private final String code;

    ValidationFailure(String code, String message) {
      super(message);
      this.code = code;
    }

    String code() {
      return code;
    }
  }
}
