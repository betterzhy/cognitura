import Ajv2020 from "ajv/dist/2020.js";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const testDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(testDirectory, "../../..");

function fail(category, message) {
  process.stderr.write(`${category}: ${message}\n`);
  process.exit(1);
}

void Ajv2020;

function readJson(relativePath) {
  const absolutePath = path.join(repositoryRoot, relativePath);
  if (!fs.existsSync(absolutePath)) {
    fail("SCHEMA_PARSE_ERROR", `missing ${relativePath}`);
  }
  try {
    return JSON.parse(fs.readFileSync(absolutePath, "utf8"));
  } catch (error) {
    fail("SCHEMA_PARSE_ERROR", `${relativePath}: ${error.message}`);
  }
}

const catalog = readJson("schemas/catalog.json");
if (catalog.catalogVersion !== "2.0.0" || !Array.isArray(catalog.schemas)) {
  fail("META_SCHEMA_INVALID", "schemas/catalog.json has an invalid catalog contract");
}

const ids = new Set();
const schemaDocuments = new Map();
for (const entry of catalog.schemas) {
  if (ids.has(entry.id)) {
    fail("META_SCHEMA_INVALID", `duplicate catalog id ${entry.id}`);
  }
  ids.add(entry.id);
  if (!entry.id.startsWith("urn:cognitura:schema:")) {
    fail("NETWORK_RESOLUTION_FORBIDDEN", entry.id);
  }
  const schema = readJson(entry.path);
  if (schema.$id !== entry.id) {
    fail("META_SCHEMA_INVALID", `${entry.path} does not match catalog id ${entry.id}`);
  }
  schemaDocuments.set(entry.id, schema);
}

if (catalog.schemas.length !== 14) {
  fail("META_SCHEMA_INVALID", `expected 14 Schema documents, found ${catalog.schemas.length}`);
}

const instantiableEntries = catalog.schemas.filter((entry) => entry.instantiable);
if (instantiableEntries.length !== 13) {
  fail("META_SCHEMA_INVALID", `expected 13 instantiable Schemas, found ${instantiableEntries.length}`);
}

function walk(value, visitor, pointer = "") {
  visitor(value, pointer);
  if (Array.isArray(value)) {
    value.forEach((item, index) => walk(item, visitor, `${pointer}/${index}`));
    return;
  }
  if (value && typeof value === "object") {
    for (const [key, child] of Object.entries(value)) {
      const escapedKey = key.replaceAll("~", "~0").replaceAll("/", "~1");
      walk(child, visitor, `${pointer}/${escapedKey}`);
    }
  }
}

for (const [schemaId, schema] of schemaDocuments) {
  walk(schema, (value, pointer) => {
    if (pointer.endsWith("/$ref") && typeof value === "string") {
      if (!value.startsWith("#") && !value.startsWith("urn:cognitura:schema:")) {
        fail("NETWORK_RESOLUTION_FORBIDDEN", `${schemaId}${pointer} -> ${value}`);
      }
    }
  });
}

class SemanticViolation extends Error {
  constructor(code, message) {
    super(message);
    this.name = "SemanticViolation";
    this.code = code;
  }
}

let semanticEvidenceByViolationCode;

function semanticAssert(condition, code, message) {
  if (
    semanticEvidenceByViolationCode !== undefined &&
    !semanticEvidenceByViolationCode.has(code)
  ) {
    fail(
      "EVIDENCE_MAPPING_MISSING",
      `runtime semantic violation code ${code} has no evidence policy`
    );
  }
  if (!condition) {
    throw new SemanticViolation(code, message);
  }
}

function uniqueValues(values) {
  return new Set(values).size === values.length;
}

function assertUniqueField(items, field, code, ownerId) {
  semanticAssert(
    uniqueValues(items.map((item) => item[field])),
    code,
    ownerId
  );
}

function equalSets(left, right) {
  const leftSet = new Set(left);
  const rightSet = new Set(right);
  return (
    leftSet.size === rightSet.size &&
    [...leftSet].every((value) => rightSet.has(value))
  );
}

function sourceRefsFrom(items) {
  return items.flatMap((item) => item.sourceRefs ?? []);
}

function resolveJsonPointer(document, pointer) {
  if (pointer === "") {
    return {found: true, value: document};
  }
  if (!pointer.startsWith("/")) {
    return {found: false, value: undefined};
  }
  let current = document;
  for (const token of pointer.slice(1).split("/")) {
    const key = token.replaceAll("~1", "/").replaceAll("~0", "~");
    if (
      current === null ||
      typeof current !== "object" ||
      !Object.prototype.hasOwnProperty.call(current, key)
    ) {
      return {found: false, value: undefined};
    }
    current = current[key];
  }
  return {found: true, value: current};
}

function validateSemanticContext(context) {
  const artifacts = new Map();
  const referenceRegistry = new Map();
  const candidateIds = new Set();
  const candidateThemeById = new Map();
  const externalArtifacts = new Map();

  function registerArtifact(type, artifact) {
    semanticAssert(
      artifact && typeof artifact.artifactId === "string",
      "ARTIFACT_ID_MISSING",
      `${type} has no artifactId`
    );
    semanticAssert(
      !referenceRegistry.has(artifact.artifactId),
      "DUPLICATE_ARTIFACT_REVISION",
      `${artifact.artifactId} appears more than once in one revision context`
    );
    const record = {
      type,
      value: artifact,
      ownerId: artifact.artifactId,
      ownerKey: `${type}:${artifact.artifactId}`
    };
    artifacts.set(artifact.artifactId, record);
    referenceRegistry.set(artifact.artifactId, record);
  }

  function registerOwnedReference(type, id, ownerId, ownerKey, value, duplicateCode) {
    semanticAssert(
      typeof id === "string" && !referenceRegistry.has(id),
      duplicateCode,
      `${id} is not unique in the revision context`
    );
    referenceRegistry.set(id, {type, value, ownerId, ownerKey});
  }

  for (const external of context.externalArtifacts ?? []) {
    semanticAssert(
      external &&
      typeof external.artifactId === "string" &&
      ["SourceDocument", "DocumentBlock"].includes(external.artifactType),
      "REFERENCE_TARGET_TYPE_MISMATCH",
      "external artifact metadata is invalid"
    );
    semanticAssert(
      !externalArtifacts.has(external.artifactId),
      "DUPLICATE_ARTIFACT_REVISION",
      external.artifactId
    );
    externalArtifacts.set(external.artifactId, external);
  }

  registerArtifact("KnowledgeSkeleton", context.skeleton);
  for (const theme of context.skeleton.themes) {
    registerArtifact("KnowledgeTheme", theme);
    for (const candidate of theme.moduleCandidates) {
      semanticAssert(
        !candidateIds.has(candidate.moduleId),
        "DUPLICATE_MODULE_CANDIDATE",
        candidate.moduleId
      );
      candidateIds.add(candidate.moduleId);
      candidateThemeById.set(candidate.moduleId, theme.artifactId);
    }
  }
  for (const module of context.modules) {
    registerArtifact("CognitiveModule", module);
    if (module.primaryCognitiveSpine !== null) {
      registerArtifact("PrimaryCognitiveSpine", module.primaryCognitiveSpine);
    }
    for (const element of module.knowledgeElements) {
      registerArtifact("KnowledgeElement", element);
    }
    if (module.qualityAssessment !== null) {
      registerArtifact("QualityAssessment", module.qualityAssessment);
    }
  }
  for (const spine of context.additionalSpines ?? []) {
    registerArtifact("PrimaryCognitiveSpine", spine);
  }
  for (const closure of context.themeClosures) {
    registerArtifact("ThemeClosure", closure);
  }
  for (const closure of context.landscapeClosures) {
    registerArtifact("LandscapeClosure", closure);
  }
  for (const ambiguity of context.structureAmbiguities) {
    registerArtifact("StructureAmbiguity", ambiguity);
  }
  for (const evidence of context.evidenceReferences) {
    registerArtifact("EvidenceReference", evidence);
  }

  const resolveReference = (
    artifactId,
    expectedTypes,
    code = "DANGLING_REFERENCE"
  ) => {
    const record = referenceRegistry.get(artifactId);
    semanticAssert(record, code, artifactId);
    if (expectedTypes) {
      semanticAssert(
        expectedTypes.includes(record.type),
        "REFERENCE_TARGET_TYPE_MISMATCH",
        `${artifactId} is ${record.type}, expected ${expectedTypes.join("/")}`
      );
    }
    return record;
  };

  const getArtifact = (artifactId, expectedTypes, code = "DANGLING_REFERENCE") => {
    const record = resolveReference(artifactId, expectedTypes, code);
    return record.value;
  };

  const resolveExternal = (artifactId, expectedType) => {
    const record = externalArtifacts.get(artifactId);
    semanticAssert(record, "SOURCE_BLOCK_OUT_OF_CONTEXT", artifactId);
    semanticAssert(
      record.artifactType === expectedType,
      "REFERENCE_TARGET_TYPE_MISMATCH",
      `${artifactId} is ${record.artifactType}, expected ${expectedType}`
    );
    return record;
  };

  const skeleton = context.skeleton;
  const themeIds = new Set(skeleton.themes.map((theme) => theme.artifactId));
  semanticAssert(
    uniqueValues(skeleton.themes.map((theme) => theme.artifactId)),
    "DUPLICATE_THEME_ID",
    "Skeleton Theme IDs must be unique"
  );
  for (const themeRef of skeleton.coreThemeRefs) {
    semanticAssert(themeIds.has(themeRef), "CORE_THEME_OUT_OF_SCOPE", themeRef);
  }

  for (const theme of skeleton.themes) {
    semanticAssert(
      theme.primaryParent === skeleton.artifactId,
      "DANGLING_PARENT",
      `${theme.artifactId} -> ${theme.primaryParent}`
    );
    const localCandidates = new Set(theme.moduleCandidates.map((candidate) => candidate.moduleId));
    for (const candidate of theme.moduleCandidates) {
      semanticAssert(
        candidate.primaryParent === theme.artifactId,
        "DANGLING_PARENT",
        `${candidate.moduleId} -> ${candidate.primaryParent}`
      );
    }
    for (const moduleRef of theme.coreModuleRefs) {
      semanticAssert(localCandidates.has(moduleRef), "CORE_MODULE_OUT_OF_SCOPE", moduleRef);
    }
  }

  const modulesById = new Map(context.modules.map((module) => [module.artifactId, module]));
  const modulesByTheme = new Map(skeleton.themes.map((theme) => [theme.artifactId, new Set()]));
  for (const module of context.modules) {
    getArtifact(module.primaryParent, ["KnowledgeTheme"], "DANGLING_PARENT");
    semanticAssert(
      candidateThemeById.get(module.artifactId) === module.primaryParent,
      "MODULE_NOT_CONFIRMED_CANDIDATE",
      `${module.artifactId} is not a candidate of ${module.primaryParent}`
    );
    semanticAssert(
      modulesByTheme.has(module.primaryParent),
      "DANGLING_PARENT",
      `${module.artifactId} -> ${module.primaryParent}`
    );
    modulesByTheme.get(module.primaryParent).add(module.artifactId);
    if (module.primaryCognitiveSpine !== null) {
      semanticAssert(
        module.primaryCognitiveSpine.moduleRef === module.artifactId,
        "SPINE_MODULE_MISMATCH",
        `${module.primaryCognitiveSpine.artifactId} -> ${module.primaryCognitiveSpine.moduleRef}`
      );
    }
  }

  const allSpines = [
    ...context.modules.flatMap((module) => (
      module.primaryCognitiveSpine === null ? [] : [module.primaryCognitiveSpine]
    )),
    ...(context.additionalSpines ?? [])
  ];
  for (const module of context.modules) {
    const moduleSpines = allSpines.filter((spine) => spine.moduleRef === module.artifactId);
    const expectedSpineCount = module.primaryCognitiveSpine === null ? 0 : 1;
    semanticAssert(
      moduleSpines.length === expectedSpineCount,
      "MULTIPLE_PRIMARY_SPINES",
      `${module.artifactId} has ${moduleSpines.length} spines`
    );
  }
  for (const spine of allSpines) {
    semanticAssert(modulesById.has(spine.moduleRef), "DANGLING_MODULE_REF", spine.moduleRef);
    const orders = spine.steps.map((step) => step.order);
    semanticAssert(
      uniqueValues(spine.steps.map((step) => step.stepId)),
      "DUPLICATE_SPINE_STEP_ID",
      spine.artifactId
    );
    semanticAssert(
      orders.every((order, index) => order === index + 1),
      "SPINE_ORDER_NOT_CONTIGUOUS",
      spine.artifactId
    );
  }

  const evidenceById = new Map(context.evidenceReferences.map((evidence) => (
    [evidence.artifactId, evidence]
  )));
  const gapOwners = new Map();

  function registerGaps(ownerId, ownerKey, gaps) {
    const ids = gaps.map((gap) => gap.gapId);
    semanticAssert(uniqueValues(ids), "DUPLICATE_GAP_ID", ownerId);
    for (const gap of gaps) {
      registerOwnedReference(
        "Gap",
        gap.gapId,
        ownerId,
        ownerKey,
        gap,
        "DUPLICATE_GAP_ID"
      );
    }
    gapOwners.set(ownerKey, new Set(ids));
  }

  function registerRelations(ownerId, ownerKey, relations) {
    assertUniqueField(relations, "relationId", "DUPLICATE_RELATION_ID", ownerId);
    for (const relation of relations) {
      registerOwnedReference(
        "Relation",
        relation.relationId,
        ownerId,
        ownerKey,
        relation,
        "DUPLICATE_RELATION_ID"
      );
    }
  }

  registerGaps(
    skeleton.artifactId,
    `KnowledgeSkeleton:${skeleton.artifactId}`,
    skeleton.gaps
  );
  registerRelations(
    skeleton.artifactId,
    `KnowledgeSkeleton:${skeleton.artifactId}`,
    skeleton.relations
  );
  for (const theme of skeleton.themes) {
    registerGaps(
      theme.artifactId,
      `KnowledgeTheme:${theme.artifactId}`,
      theme.gaps
    );
    registerRelations(
      theme.artifactId,
      `KnowledgeTheme:${theme.artifactId}`,
      theme.relations
    );
    for (const candidate of theme.moduleCandidates) {
      registerGaps(
        candidate.moduleId,
        `ModuleCandidate:${candidate.moduleId}`,
        candidate.gaps
      );
    }
  }
  for (const module of context.modules) {
    registerGaps(
      module.artifactId,
      `CognitiveModule:${module.artifactId}`,
      module.gaps
    );
    registerRelations(
      module.artifactId,
      `CognitiveModule:${module.artifactId}`,
      module.relations
    );
  }
  for (const closure of context.themeClosures) {
    registerGaps(
      closure.artifactId,
      `ThemeClosure:${closure.artifactId}`,
      closure.gaps
    );
    registerRelations(
      closure.artifactId,
      `ThemeClosure:${closure.artifactId}`,
      closure.relatedThemes
    );
  }
  for (const closure of context.landscapeClosures) {
    registerGaps(
      closure.artifactId,
      `LandscapeClosure:${closure.artifactId}`,
      closure.gaps
    );
    registerRelations(
      closure.artifactId,
      `LandscapeClosure:${closure.artifactId}`,
      closure.keyDependencies
    );
  }

  function checkEvidenceRefs(sourceRefs, ownerId) {
    semanticAssert(uniqueValues(sourceRefs), "DUPLICATE_EVIDENCE_REF", ownerId);
    for (const sourceRef of sourceRefs) {
      const evidence = resolveReference(
        sourceRef,
        ["EvidenceReference"],
        "DANGLING_EVIDENCE_REF"
      ).value;
      semanticAssert(
        evidence.supports.includes(ownerId),
        "EVIDENCE_DOES_NOT_SUPPORT_OWNER",
        `${sourceRef} does not support ${ownerId}`
      );
    }
  }

  function checkGapRefs(gapRefs, ownerKey, code) {
    semanticAssert(uniqueValues(gapRefs), code, ownerKey);
    for (const gapRef of gapRefs) {
      const record = referenceRegistry.get(gapRef);
      semanticAssert(
        record && record.type === "Gap" && record.ownerKey === ownerKey,
        code,
        `${gapRef} is not owned by ${ownerKey}`
      );
    }
  }

  function checkGapSources(gaps, ownerId) {
    for (const gap of gaps) {
      checkEvidenceRefs(gap.sourceRefs, ownerId);
    }
  }

  function checkSourceCoverage(
    ownerId,
    ownerKey,
    sourceCoverage,
    gaps,
    carriedEvidenceRefs = null
  ) {
    semanticAssert(
      equalSets(sourceCoverage.gapRefs, gaps.map((gap) => gap.gapId)),
      "SOURCE_COVERAGE_GAP_MISMATCH",
      ownerId
    );
    checkGapRefs(
      sourceCoverage.gapRefs,
      ownerKey,
      "SOURCE_COVERAGE_GAP_MISMATCH"
    );
    checkEvidenceRefs(sourceCoverage.evidenceRefs, ownerId);
    checkGapSources(gaps, ownerId);
    if (
      sourceCoverage.status === "COMPLETE" &&
      carriedEvidenceRefs !== null
    ) {
      semanticAssert(
        equalSets(sourceCoverage.evidenceRefs, carriedEvidenceRefs),
        "SOURCE_COVERAGE_UNION_MISMATCH",
        ownerId
      );
    }
  }

  function checkEvidenceStatements(items, ownerId, ownerKey) {
    for (const item of items) {
      checkEvidenceRefs(item.sourceRefs, ownerId);
      checkGapRefs(item.gapRefs, ownerKey, "STATEMENT_GAP_OUT_OF_SCOPE");
    }
  }

  for (const spine of allSpines) {
    for (const step of spine.steps) {
      checkEvidenceRefs(step.sourceRefs, spine.artifactId);
    }
  }

  for (const module of context.modules) {
    const relations = new Map();
    const moduleOwnerKey = `CognitiveModule:${module.artifactId}`;
    assertUniqueField(module.facets, "facetId", "DUPLICATE_FACET_ID", module.artifactId);
    assertUniqueField(
      module.keyTakeaways,
      "statementId",
      "DUPLICATE_STATEMENT_ID",
      module.artifactId
    );
    assertUniqueField(
      module.criticalBoundaries,
      "boundaryId",
      "DUPLICATE_BOUNDARY_ID",
      module.artifactId
    );
    for (const relation of module.relations) {
      semanticAssert(
        !relations.has(relation.relationId),
        "DUPLICATE_RELATION_ID",
        relation.relationId
      );
      semanticAssert(
        relation.sourceRef !== relation.targetRef,
        "RELATION_SELF_REFERENCE",
        relation.relationId
      );
      relations.set(relation.relationId, relation);
      const elementIds = new Set(
        module.knowledgeElements.map((element) => element.artifactId)
      );
      semanticAssert(
        elementIds.has(relation.sourceRef) && elementIds.has(relation.targetRef),
        "RELATION_TARGET_OUT_OF_SCOPE",
        relation.relationId
      );
      checkEvidenceRefs(relation.sourceRefs, module.artifactId);
      checkGapRefs(
        relation.gapRefs,
        moduleOwnerKey,
        "RELATION_GAP_OUT_OF_SCOPE"
      );
    }
    const elementIds = new Set(module.knowledgeElements.map((element) => element.artifactId));
    for (const facet of module.facets) {
      semanticAssert(
        facet.elementRefs.every((elementRef) => elementIds.has(elementRef)),
        "FACET_ELEMENT_OUT_OF_SCOPE",
        facet.facetId
      );
      checkEvidenceRefs(facet.sourceRefs, module.artifactId);
    }
    for (const element of module.knowledgeElements) {
      semanticAssert(element.moduleRef === module.artifactId, "ELEMENT_MODULE_MISMATCH", element.artifactId);
      checkEvidenceRefs(element.sourceRefs, element.artifactId);
      for (const relationRef of element.relations) {
        const relation = relations.get(relationRef);
        semanticAssert(
          relation &&
          (relation.sourceRef === element.artifactId || relation.targetRef === element.artifactId),
          "ELEMENT_RELATION_OUT_OF_SCOPE",
          `${element.artifactId} -> ${relationRef}`
        );
        const relationRecord = resolveReference(
          relationRef,
          ["Relation"],
          "ELEMENT_RELATION_OUT_OF_SCOPE"
        );
        semanticAssert(
          relationRecord.ownerKey === moduleOwnerKey,
          "ELEMENT_RELATION_OUT_OF_SCOPE",
          `${element.artifactId} -> ${relationRef}`
        );
      }
    }
    checkEvidenceStatements(
      module.keyTakeaways,
      module.artifactId,
      moduleOwnerKey
    );
    for (const boundary of module.criticalBoundaries) {
      checkEvidenceRefs(boundary.sourceRefs, module.artifactId);
    }
    checkEvidenceRefs(module.sourceRefs, module.artifactId);
    checkGapSources(module.gaps, module.artifactId);
    if (module.qualityAssessment !== null) {
      semanticAssert(
        module.qualityAssessment.subjectRef === module.artifactId,
        "QUALITY_SUBJECT_MISMATCH",
        module.artifactId
      );
      getArtifact(
        module.qualityAssessment.subjectRef,
        [
          "KnowledgeSkeleton",
          "KnowledgeTheme",
          "CognitiveModule",
          "ThemeClosure",
          "LandscapeClosure"
        ]
      );
      for (const dimensionName of [
        "hierarchyCorrectness",
        "granularityFitness",
        "cognitiveClosure",
        "spineCoherence",
        "importanceAccuracy",
        "sourceFaithfulness",
        "compressionEfficiency"
      ]) {
        for (const finding of module.qualityAssessment[dimensionName].findings) {
          for (const artifactRef of finding.artifactRefs) {
            resolveReference(artifactRef);
          }
          checkEvidenceRefs(finding.sourceRefs, module.artifactId);
        }
      }
    }
  }

  checkSourceCoverage(
    skeleton.artifactId,
    `KnowledgeSkeleton:${skeleton.artifactId}`,
    skeleton.sourceCoverage,
    skeleton.gaps,
    sourceRefsFrom(skeleton.relations)
  );
  for (const ambiguityRef of skeleton.structureAmbiguityRefs) {
    getArtifact(ambiguityRef, ["StructureAmbiguity"]);
  }
  for (const theme of skeleton.themes) {
    checkSourceCoverage(
      theme.artifactId,
      `KnowledgeTheme:${theme.artifactId}`,
      theme.sourceCoverage,
      theme.gaps,
      sourceRefsFrom(theme.relations)
    );
    for (const candidate of theme.moduleCandidates) {
      checkSourceCoverage(
        candidate.moduleId,
        `ModuleCandidate:${candidate.moduleId}`,
        candidate.sourceCoverage,
        candidate.gaps
      );
    }
  }

  function checkScopedRelations(ownerId, ownerKey, relations, allowedRefs) {
    assertUniqueField(relations, "relationId", "DUPLICATE_RELATION_ID", ownerId);
    for (const relation of relations) {
      semanticAssert(
        relation.sourceRef !== relation.targetRef &&
        allowedRefs.has(relation.sourceRef) &&
        allowedRefs.has(relation.targetRef),
        "RELATION_TARGET_OUT_OF_SCOPE",
        relation.relationId
      );
      checkEvidenceRefs(relation.sourceRefs, ownerId);
      checkGapRefs(
        relation.gapRefs,
        ownerKey,
        "RELATION_GAP_OUT_OF_SCOPE",
        relation.relationId
      );
    }
  }

  checkScopedRelations(
    skeleton.artifactId,
    `KnowledgeSkeleton:${skeleton.artifactId}`,
    skeleton.relations,
    themeIds
  );
  semanticAssert(
    skeleton.understandingRoute.every((artifactRef) => (
      themeIds.has(artifactRef) || modulesById.has(artifactRef)
    )),
    "UNDERSTANDING_ROUTE_OUT_OF_SCOPE",
    skeleton.artifactId
  );
  for (const theme of skeleton.themes) {
    checkScopedRelations(
      theme.artifactId,
      `KnowledgeTheme:${theme.artifactId}`,
      theme.relations,
      new Set(theme.moduleCandidates.map((candidate) => candidate.moduleId))
    );
  }

  for (const closure of context.themeClosures) {
    getArtifact(closure.themeRef, ["KnowledgeTheme"]);
    const closureOwnerKey = `ThemeClosure:${closure.artifactId}`;
    const allowedModules = modulesByTheme.get(closure.themeRef) ?? new Set();
    checkSourceCoverage(
      closure.artifactId,
      closureOwnerKey,
      closure.sourceCoverage,
      closure.gaps
    );
    assertUniqueField(
      closure.moduleCooperation,
      "moduleRef",
      "DUPLICATE_MODULE_COOPERATION",
      closure.artifactId
    );
    for (const cooperation of closure.moduleCooperation) {
      const record = referenceRegistry.get(cooperation.moduleRef);
      semanticAssert(
        record &&
        record.type === "CognitiveModule" &&
        allowedModules.has(cooperation.moduleRef),
        "THEME_CLOSURE_MODULE_OUT_OF_SCOPE",
        cooperation.moduleRef
      );
      checkEvidenceRefs(cooperation.sourceRefs, closure.artifactId);
    }
    assertUniqueField(closure.themeSpine, "stepId", "DUPLICATE_SPINE_STEP_ID", closure.artifactId);
    semanticAssert(
      closure.themeSpine.every((step, index) => step.order === index + 1),
      "SPINE_ORDER_NOT_CONTIGUOUS",
      closure.artifactId
    );
    for (const step of closure.themeSpine) {
      const record = referenceRegistry.get(step.artifactRef);
      semanticAssert(
        record &&
        record.type === "CognitiveModule" &&
        allowedModules.has(step.artifactRef),
        "THEME_CLOSURE_MODULE_OUT_OF_SCOPE",
        step.artifactRef
      );
      checkEvidenceRefs(step.sourceRefs, closure.artifactId);
    }
    assertUniqueField(
      closure.criticalDistinctions,
      "statementId",
      "DUPLICATE_STATEMENT_ID",
      closure.artifactId
    );
    assertUniqueField(closure.boundaries, "statementId", "DUPLICATE_STATEMENT_ID", closure.artifactId);
    checkEvidenceStatements(
      closure.criticalDistinctions,
      closure.artifactId,
      closureOwnerKey
    );
    checkEvidenceStatements(
      closure.boundaries,
      closure.artifactId,
      closureOwnerKey
    );
    checkScopedRelations(
      closure.artifactId,
      closureOwnerKey,
      closure.relatedThemes,
      themeIds
    );
    const carriedEvidence = [
      ...sourceRefsFrom(closure.moduleCooperation),
      ...sourceRefsFrom(closure.themeSpine),
      ...sourceRefsFrom(closure.criticalDistinctions),
      ...sourceRefsFrom(closure.boundaries),
      ...sourceRefsFrom(closure.relatedThemes)
    ];
    semanticAssert(
      equalSets(closure.sourceCoverage.evidenceRefs, carriedEvidence),
      "SOURCE_COVERAGE_UNION_MISMATCH",
      closure.artifactId
    );
  }

  for (const closure of context.landscapeClosures) {
    const closureOwnerKey = `LandscapeClosure:${closure.artifactId}`;
    checkSourceCoverage(
      closure.artifactId,
      closureOwnerKey,
      closure.sourceCoverage,
      closure.gaps
    );
    assertUniqueField(closure.coreThemes, "themeRef", "DUPLICATE_CORE_THEME", closure.artifactId);
    assertUniqueField(
      closure.crossThemeSpine,
      "stepId",
      "DUPLICATE_SPINE_STEP_ID",
      closure.artifactId
    );
    semanticAssert(
      closure.crossThemeSpine.every((step, index) => step.order === index + 1),
      "SPINE_ORDER_NOT_CONTIGUOUS",
      closure.artifactId
    );
    assertUniqueField(
      closure.globalBoundaries,
      "statementId",
      "DUPLICATE_STATEMENT_ID",
      closure.artifactId
    );
    checkScopedRelations(
      closure.artifactId,
      closureOwnerKey,
      closure.keyDependencies,
      themeIds
    );
    for (const coreTheme of closure.coreThemes) {
      semanticAssert(
        themeIds.has(coreTheme.themeRef),
        "LANDSCAPE_THEME_OUT_OF_SCOPE",
        coreTheme.themeRef
      );
      getArtifact(coreTheme.themeRef, ["KnowledgeTheme"]);
      checkEvidenceRefs(coreTheme.sourceRefs, closure.artifactId);
    }
    for (const step of closure.crossThemeSpine) {
      const record = referenceRegistry.get(step.artifactRef);
      semanticAssert(
        record &&
        record.type === "KnowledgeTheme" &&
        themeIds.has(step.artifactRef),
        "LANDSCAPE_THEME_OUT_OF_SCOPE",
        step.artifactRef
      );
      checkEvidenceRefs(step.sourceRefs, closure.artifactId);
    }
    for (const routeRef of closure.understandingRoute) {
      const record = referenceRegistry.get(routeRef);
      semanticAssert(
        record &&
        (
          (record.type === "KnowledgeTheme" && themeIds.has(routeRef)) ||
          (
            record.type === "CognitiveModule" &&
            themeIds.has(record.value.primaryParent)
          )
        ),
        "LANDSCAPE_ROUTE_OUT_OF_SCOPE",
        routeRef
      );
    }
    checkEvidenceStatements(
      closure.globalBoundaries,
      closure.artifactId,
      closureOwnerKey
    );
    const carriedEvidence = [
      ...sourceRefsFrom(closure.coreThemes),
      ...sourceRefsFrom(closure.crossThemeSpine),
      ...sourceRefsFrom(closure.keyDependencies),
      ...sourceRefsFrom(closure.globalBoundaries)
    ];
    semanticAssert(
      equalSets(closure.sourceCoverage.evidenceRefs, carriedEvidence),
      "SOURCE_COVERAGE_UNION_MISMATCH",
      closure.artifactId
    );
  }

  const supportedTargets = new Set([...artifacts.keys(), ...candidateIds]);
  for (const evidence of context.evidenceReferences) {
    resolveExternal(evidence.sourceDocumentRef, "SourceDocument");
    resolveExternal(evidence.documentBlockRef, "DocumentBlock");
    for (const supportedRef of evidence.supports) {
      semanticAssert(supportedTargets.has(supportedRef), "EVIDENCE_SUPPORT_TARGET_MISSING", supportedRef);
    }
  }

  const expectedConflictGroups = new Map();
  for (const membership of context.conflictMembership ?? []) {
    semanticAssert(
      membership &&
      typeof membership.groupId === "string" &&
      Array.isArray(membership.memberRefs) &&
      membership.memberRefs.length >= 2 &&
      uniqueValues(membership.memberRefs),
      "CONFLICT_MEMBERSHIP_INVALID",
      String(membership?.groupId)
    );
    semanticAssert(
      !expectedConflictGroups.has(membership.groupId),
      "CONFLICT_MEMBERSHIP_INVALID",
      membership.groupId
    );
    expectedConflictGroups.set(membership.groupId, new Set(membership.memberRefs));
  }

  const conflictGroups = new Map();
  for (const evidence of context.evidenceReferences) {
    if (evidence.conflictState === "NONE") {
      continue;
    }
    const group = conflictGroups.get(evidence.conflictGroupId) ?? [];
    group.push(evidence);
    conflictGroups.set(evidence.conflictGroupId, group);
    if (evidence.conflictState === "RESOLVED_BY_USER") {
      semanticAssert(
        evidence.resolutionDecision?.decidedBy === "USER",
        "CONFLICT_RESOLUTION_NOT_USER",
        evidence.artifactId
      );
    }
  }
  for (const [groupId, members] of conflictGroups) {
    semanticAssert(members.length >= 2, "CONFLICT_GROUP_SINGLETON", groupId);
    const actualMemberIds = members.map((member) => member.artifactId);
    const expectedMemberIds = expectedConflictGroups.get(groupId);
    semanticAssert(
      expectedMemberIds && equalSets(actualMemberIds, [...expectedMemberIds]),
      "CONFLICT_SOURCE_HIDDEN",
      groupId
    );
    const decisions = members
      .map((member) => member.resolutionDecision)
      .filter((decision) => decision !== null);
    if (decisions.length > 0) {
      const canonical = JSON.stringify(decisions[0]);
      semanticAssert(
        decisions.length === members.length &&
        decisions.every((decision) => JSON.stringify(decision) === canonical),
        "CONFLICT_DECISION_MISMATCH",
        groupId
      );
      const preferredRef = decisions[0].preferredEvidenceRef;
      semanticAssert(
        preferredRef === null || members.some((member) => member.artifactId === preferredRef),
        "PREFERRED_EVIDENCE_OUT_OF_GROUP",
        groupId
      );
    }
  }
  for (const groupId of expectedConflictGroups.keys()) {
    semanticAssert(
      conflictGroups.has(groupId),
      "CONFLICT_SOURCE_HIDDEN",
      groupId
    );
  }

  for (const ambiguity of context.structureAmbiguities) {
    getArtifact(ambiguity.locationRef, ["KnowledgeTheme", "CognitiveModule", "KnowledgeElement"]);
    for (const affectedRef of ambiguity.recommendedStructure.affectedRefs) {
      semanticAssert(
        supportedTargets.has(affectedRef),
        "DANGLING_REFERENCE",
        affectedRef
      );
    }
    for (const alternative of ambiguity.alternatives) {
      for (const affectedRef of alternative.affectedRefs) {
        semanticAssert(
          supportedTargets.has(affectedRef),
          "DANGLING_REFERENCE",
          affectedRef
        );
      }
    }
    for (const impact of ambiguity.closureImpacts) {
      getArtifact(
        impact.scopeRef,
        ["KnowledgeTheme", "CognitiveModule", "ThemeClosure", "LandscapeClosure"]
      );
    }
    assertUniqueField(
      ambiguity.alternatives,
      "alternativeId",
      "DUPLICATE_ALTERNATIVE_ID",
      ambiguity.artifactId
    );
    checkEvidenceRefs(ambiguity.sourceRefs, ambiguity.artifactId);
    for (const gapRef of ambiguity.gapRefs) {
      resolveReference(gapRef, ["Gap"], "AMBIGUITY_GAP_OUT_OF_SCOPE");
    }
  }

  function resolveRendererProjection(module, node) {
    const resolved = resolveJsonPointer(module, node.contentPath);
    semanticAssert(
      resolved.found,
      "RENDERER_CONTENT_PATH_UNRESOLVED",
      node.contentPath
    );

    const directModuleFields = new Set(["/title", "/thesis", "/role"]);
    if (directModuleFields.has(node.contentPath)) {
      return {
        entityRef: module.artifactId,
        orderGroup: null,
        orderIndex: null
      };
    }

    const patterns = [
      {
        pattern: /^\/coreQuestions\/(\d+)$/,
        collection: "coreQuestions",
        entity: () => module.artifactId
      },
      {
        pattern: /^\/primaryCognitiveSpine\/steps\/(\d+)\/statement$/,
        collection: "primaryCognitiveSpine.steps",
        entity: (index) => module.primaryCognitiveSpine?.steps[index]?.stepId
      },
      {
        pattern: /^\/facets\/(\d+)\/(?:title|summary)$/,
        collection: "facets",
        entity: (index) => module.facets[index]?.facetId
      },
      {
        pattern: /^\/knowledgeElements\/(\d+)\/(?:title|content)$/,
        collection: "knowledgeElements",
        entity: (index) => module.knowledgeElements[index]?.artifactId
      },
      {
        pattern: /^\/keyTakeaways\/(\d+)\/statement$/,
        collection: "keyTakeaways",
        entity: (index) => module.keyTakeaways[index]?.statementId
      },
      {
        pattern: /^\/criticalBoundaries\/(\d+)\/statement$/,
        collection: "criticalBoundaries",
        entity: (index) => module.criticalBoundaries[index]?.boundaryId
      }
    ];

    for (const descriptor of patterns) {
      const match = descriptor.pattern.exec(node.contentPath);
      if (match) {
        const orderIndex = Number(match[1]);
        const entityRef = descriptor.entity(orderIndex);
        semanticAssert(
          typeof entityRef === "string",
          "RENDERER_CONTENT_PATH_UNRESOLVED",
          node.contentPath
        );
        return {
          entityRef,
          orderGroup: descriptor.collection,
          orderIndex
        };
      }
    }

    semanticAssert(
      false,
      "RENDERER_CONTENT_PATH_NOT_COGNITIVE",
      node.contentPath
    );
  }

  for (const renderer of context.rendererInputs) {
    const module = getArtifact(renderer.moduleRef, ["CognitiveModule"]);
    const nodeIds = new Set(renderer.nodes.map((node) => node.nodeId));
    const groupIds = new Set(renderer.groups.map((group) => group.groupId));
    semanticAssert(nodeIds.size === renderer.nodes.length, "DUPLICATE_RENDERER_NODE", renderer.moduleRef);
    semanticAssert(groupIds.size === renderer.groups.length, "DUPLICATE_RENDERER_GROUP", renderer.moduleRef);
    const nodeProjections = new Map();
    const lastOrderByCollection = new Map();
    for (const node of renderer.nodes) {
      semanticAssert(
        node.artifactRef === renderer.moduleRef,
        "RENDERER_CROSS_MODULE",
        node.nodeId
      );
      const projection = resolveRendererProjection(module, node);
      nodeProjections.set(node.nodeId, projection);
      if (projection.orderGroup !== null) {
        const lastOrder = lastOrderByCollection.get(projection.orderGroup);
        semanticAssert(
          lastOrder === undefined || projection.orderIndex >= lastOrder,
          "RENDERER_COGNITIVE_ORDER_CHANGED",
          projection.orderGroup
        );
        lastOrderByCollection.set(
          projection.orderGroup,
          projection.orderIndex
        );
      }
      semanticAssert(
        node.groupRef === null || groupIds.has(node.groupRef),
        "RENDERER_GROUP_REF_MISSING",
        node.nodeId
      );
      semanticAssert(
        node.sourceRefs.every((sourceRef) => module.sourceRefs.includes(sourceRef)),
        "RENDERER_SOURCE_OUT_OF_SCOPE",
        node.nodeId
      );
    }
    for (const group of renderer.groups) {
      semanticAssert(
        group.nodeRefs.every((nodeRef) => nodeIds.has(nodeRef)),
        "RENDERER_NODE_REF_MISSING",
        group.groupId
      );
    }
    const moduleRelations = new Map(module.relations.map((relation) => [relation.relationId, relation]));
    assertUniqueField(
      renderer.relations,
      "relationId",
      "DUPLICATE_RENDERER_RELATION",
      renderer.moduleRef
    );
    let previousFormalRelationIndex = -1;
    for (const relation of renderer.relations) {
      semanticAssert(
        nodeIds.has(relation.sourceNodeRef) && nodeIds.has(relation.targetNodeRef),
        "RENDERER_NODE_REF_MISSING",
        relation.relationId
      );
      semanticAssert(
        moduleRelations.has(relation.artifactRelationRef),
        "RENDERER_RELATION_OUT_OF_SCOPE",
        relation.artifactRelationRef
      );
      const formalRelation = moduleRelations.get(relation.artifactRelationRef);
      semanticAssert(
        formalRelation.type === relation.type,
        "RENDERER_RELATION_TYPE_CHANGED",
        relation.relationId
      );
      const sourceProjection = nodeProjections.get(relation.sourceNodeRef);
      const targetProjection = nodeProjections.get(relation.targetNodeRef);
      semanticAssert(
        relation.sourceNodeRef !== relation.targetNodeRef &&
        sourceProjection.entityRef === formalRelation.sourceRef &&
        targetProjection.entityRef === formalRelation.targetRef,
        "RENDERER_RELATION_ENDPOINT_CHANGED",
        relation.relationId
      );
      semanticAssert(
        equalSets(relation.sourceRefs, formalRelation.sourceRefs),
        "RENDERER_RELATION_SOURCE_CHANGED",
        relation.relationId
      );
      const formalRelationIndex = module.relations.findIndex(
        (candidate) => candidate.relationId === relation.artifactRelationRef
      );
      semanticAssert(
        formalRelationIndex > previousFormalRelationIndex,
        "RENDERER_COGNITIVE_ORDER_CHANGED",
        relation.relationId
      );
      previousFormalRelationIndex = formalRelationIndex;
      checkEvidenceRefs(relation.sourceRefs, renderer.moduleRef);
    }
    checkEvidenceRefs(renderer.sourceRefs, renderer.moduleRef);
    semanticAssert(
      renderer.sourceRefs.every((sourceRef) => module.sourceRefs.includes(sourceRef)),
      "RENDERER_SOURCE_OUT_OF_SCOPE",
      renderer.moduleRef
    );
    semanticAssert(
      renderer.incompleteState.gapRefs.every((gapRef) => (
        (
          gapOwners.get(`CognitiveModule:${module.artifactId}`) ??
          new Set()
        ).has(gapRef)
      )),
      "RENDERER_GAP_OUT_OF_SCOPE",
      renderer.moduleRef
    );
    if (renderer.nodes.length > 12) {
      const groupMembership = new Map(renderer.nodes.map((node) => [node.nodeId, 0]));
      for (const group of renderer.groups) {
        for (const nodeRef of group.nodeRefs) {
          groupMembership.set(nodeRef, groupMembership.get(nodeRef) + 1);
        }
      }
      semanticAssert(
        [...groupMembership.values()].every((count) => count === 1),
        "RENDERER_DENSITY_GROUPING_INVALID",
        renderer.moduleRef
      );
    }
  }

  const successfulRunKeys = new Set();
  for (const record of context.generationRecords) {
    for (const sourceBlockRef of record.sourceBlockRefs) {
      resolveExternal(sourceBlockRef, "DocumentBlock");
    }
    for (const retryScopeRef of record.retryScopeRefs) {
      semanticAssert(
        supportedTargets.has(retryScopeRef),
        "DANGLING_REFERENCE",
        retryScopeRef
      );
    }
    for (const failedScopeRef of record.failure?.failedScopeRefs ?? []) {
      semanticAssert(
        supportedTargets.has(failedScopeRef),
        "DANGLING_REFERENCE",
        failedScopeRef
      );
    }
    if (record.outputKind === "COGNITIVE_ARTIFACT") {
      const catalogEntry = catalog.schemas.find((entry) => entry.id === record.outputSchemaId);
      semanticAssert(
        catalogEntry &&
        record.outputSchemaId.startsWith("urn:cognitura:schema:cognition:") &&
        !record.outputSchemaId.includes(":common:"),
        "GENERATION_OUTPUT_SCHEMA_INVALID",
        String(record.outputSchemaId)
      );
      const outputValidator = validators.get(record.outputSchemaId);
      semanticAssert(
        outputValidator && outputValidator(record.structuredOutput),
        "GENERATION_OUTPUT_CONTRACT_VIOLATION",
        record.runId
      );
    }
    if (record.generationStatus === "SUCCEEDED") {
      const key = [
        record.stage,
        record.inputHash,
        record.promptVersion,
        record.schemaVersion
      ].join("|");
      semanticAssert(
        !successfulRunKeys.has(key),
        "DUPLICATE_SUCCESSFUL_RUN",
        key
      );
      successfulRunKeys.add(key);
    }
  }
}

function applySemanticMutation(context, mutation) {
  switch (mutation) {
    case "DANGLING_PARENT":
      context.modules[0].primaryParent = "theme.missing";
      break;
    case "DUPLICATE_SPINE": {
      const duplicate = structuredClone(context.modules[0].primaryCognitiveSpine);
      duplicate.artifactId = "spine.mvcc.duplicate";
      duplicate.revisionId = "rev.spine.mvcc.duplicate.1";
      context.additionalSpines.push(duplicate);
      break;
    }
    case "ELEMENT_RELATION_SCOPE":
      context.modules[0].knowledgeElements[0].relations = ["relation.missing"];
      break;
    case "SOURCE_COVERAGE_OWNER":
      context.evidenceReferences
        .find((evidence) => evidence.artifactId === "evidence.mvcc")
        .supports = ["module.mvcc", "element.visibility", "element.version", "ambiguity.mvcc.boundary"];
      break;
    case "SOURCE_COVERAGE_UNION":
      context.themeClosures[0].sourceCoverage.evidenceRefs = [];
      break;
    case "UNRESOLVED_CONFLICT_SINGLETON": {
      const evidence = context.evidenceReferences.find(
        (candidate) => candidate.artifactId === "evidence.locks"
      );
      evidence.conflictState = "UNRESOLVED";
      evidence.conflictGroupId = "conflict.singleton";
      break;
    }
    case "AUTOMATIC_CONFLICT_RESOLUTION": {
      const evidence = context.evidenceReferences.find(
        (candidate) => candidate.artifactId === "evidence.locks"
      );
      evidence.conflictState = "RESOLVED_BY_USER";
      evidence.conflictGroupId = "conflict.automatic";
      evidence.resolutionDecision = {
        decisionId: "decision.automatic",
        decidedBy: "MODEL",
        outcome: "PRESERVE_ALL",
        preferredEvidenceRef: null,
        rationale: "Automatically selected."
      };
      break;
    }
    case "RENDERER_CROSS_MODULE":
      context.rendererInputs[0].nodes[0].artifactRef = "theme.storage";
      break;
    case "RENDERER_CONTENT_PATH":
      context.rendererInputs[0].nodes[0].contentPath = "/knowledgeElements/99/content";
      break;
    case "RENDERER_RELATION_SCOPE": {
      const renderer = context.rendererInputs[0];
      renderer.nodes.push({
        nodeId: "renderer-node.mvcc.element",
        artifactRef: "module.mvcc",
        contentPath: "/knowledgeElements/0/content",
        label: "Visibility element",
        summary: "",
        groupRef: null,
        sourceRefs: ["evidence.mvcc"]
      });
      renderer.relations.push({
        relationId: "renderer-relation.missing",
        type: "DEPENDS_ON",
        sourceNodeRef: renderer.nodes[0].nodeId,
        targetNodeRef: renderer.nodes[1].nodeId,
        artifactRelationRef: "relation.missing",
        sourceRefs: ["evidence.mvcc"]
      });
      break;
    }
    case "SPINE_ORDER_GAP":
      context.modules[0].primaryCognitiveSpine.steps[3].order = 5;
      break;
    case "DUPLICATE_SUCCESSFUL_RUN": {
      const duplicate = structuredClone(context.generationRecords[0]);
      duplicate.runId = "run.module.mvcc.duplicate";
      context.generationRecords.push(duplicate);
      break;
    }
    case "DANGLING_SPINE_EVIDENCE":
      context.modules[0].primaryCognitiveSpine.steps[0].sourceRefs = ["evidence.missing"];
      break;
    case "BOUNDARY_EVIDENCE_OWNER":
      context.modules[0].criticalBoundaries[0].sourceRefs = ["evidence.locks"];
      break;
    case "TAKEAWAY_GAP_OWNER":
      context.modules[0].keyTakeaways[0].gapRefs = ["gap.theme.consistency"];
      break;
    case "RELATION_GAP_OWNER":
      context.modules[0].relations[0].gapRefs = ["gap.theme.consistency"];
      break;
    case "SOURCE_DOCUMENT_TYPE":
      context.evidenceReferences[0].sourceDocumentRef = "block.mysql.mvcc.1";
      break;
    case "DOCUMENT_BLOCK_TYPE":
      context.evidenceReferences[0].documentBlockRef = "source.mysql";
      break;
    case "GENERATION_SOURCE_BLOCK_TYPE":
      context.generationRecords[0].sourceBlockRefs = ["source.mysql"];
      break;
    case "MODULE_NOT_CANDIDATE": {
      const module = context.modules[1];
      module.artifactId = "module.locking.unregistered";
      module.revisionId = "rev.module.locking.unregistered.1";
      module.knowledgeElements[0].moduleRef = module.artifactId;
      break;
    }
    case "MODULE_RELATION_CROSS_MODULE":
      context.modules[0].relations[0].targetRef = "element.lock.wait";
      break;
    case "SPINE_MODULE_MISMATCH":
      context.modules[0].primaryCognitiveSpine.moduleRef = "module.locking";
      break;
    case "THEME_CLOSURE_MODULE_SCOPE":
      context.themeClosures[0].moduleCooperation[0].moduleRef = "module.missing";
      break;
    case "THEME_CLOSURE_SPINE_SCOPE":
      context.themeClosures[0].themeSpine[0].artifactRef = "theme.storage";
      break;
    case "THEME_CLOSURE_SPINE_ORDER":
      context.themeClosures[0].themeSpine[0].order = 2;
      break;
    case "LANDSCAPE_CROSS_THEME_TYPE":
      context.landscapeClosures[0].crossThemeSpine[0].artifactRef = "module.mvcc";
      break;
    case "LANDSCAPE_ROUTE_SCOPE":
      context.landscapeClosures[0].understandingRoute[0] = "module.missing";
      break;
    case "RENDERER_METADATA_CONTENT_PATH":
      context.rendererInputs[0].nodes[0].contentPath = "/revisionId";
      break;
    case "RENDERER_RELATION_ENDPOINTS": {
      const renderer = context.rendererInputs[0];
      renderer.nodes = [
        {
          nodeId: "renderer-node.mvcc.visibility",
          artifactRef: "module.mvcc",
          contentPath: "/knowledgeElements/0/content",
          label: "Visibility judgment",
          summary: "",
          groupRef: null,
          sourceRefs: ["evidence.mvcc"]
        },
        {
          nodeId: "renderer-node.mvcc.version",
          artifactRef: "module.mvcc",
          contentPath: "/knowledgeElements/1/content",
          label: "Record version",
          summary: "",
          groupRef: null,
          sourceRefs: ["evidence.mvcc"]
        }
      ];
      renderer.relations = [
        {
          relationId: "renderer-relation.visibility.depends-version",
          type: "DEPENDS_ON",
          sourceNodeRef: "renderer-node.mvcc.version",
          targetNodeRef: "renderer-node.mvcc.visibility",
          artifactRelationRef: "relation.visibility.depends-version",
          sourceRefs: ["evidence.mvcc"]
        }
      ];
      break;
    }
    case "RENDERER_RELATION_SOURCE": {
      const renderer = context.rendererInputs[0];
      renderer.nodes = [
        {
          nodeId: "renderer-node.mvcc.visibility",
          artifactRef: "module.mvcc",
          contentPath: "/knowledgeElements/0/content",
          label: "Visibility judgment",
          summary: "",
          groupRef: null,
          sourceRefs: ["evidence.mvcc"]
        },
        {
          nodeId: "renderer-node.mvcc.version",
          artifactRef: "module.mvcc",
          contentPath: "/knowledgeElements/1/content",
          label: "Record version",
          summary: "",
          groupRef: null,
          sourceRefs: ["evidence.mvcc"]
        }
      ];
      renderer.relations = [
        {
          relationId: "renderer-relation.visibility.depends-version",
          type: "DEPENDS_ON",
          sourceNodeRef: "renderer-node.mvcc.visibility",
          targetNodeRef: "renderer-node.mvcc.version",
          artifactRelationRef: "relation.visibility.depends-version",
          sourceRefs: ["evidence.conflict.mvcc.1"]
        }
      ];
      break;
    }
    case "RENDERER_COGNITIVE_ORDER":
      context.rendererInputs[0].nodes = [
        {
          nodeId: "renderer-node.mvcc.spine.2",
          artifactRef: "module.mvcc",
          contentPath: "/primaryCognitiveSpine/steps/1/statement",
          label: "Visibility boundary",
          summary: "",
          groupRef: null,
          sourceRefs: ["evidence.mvcc"]
        },
        {
          nodeId: "renderer-node.mvcc.spine.1",
          artifactRef: "module.mvcc",
          contentPath: "/primaryCognitiveSpine/steps/0/statement",
          label: "Version creation",
          summary: "",
          groupRef: null,
          sourceRefs: ["evidence.mvcc"]
        }
      ];
      break;
    case "CONFLICT_SOURCE_HIDDEN":
      context.evidenceReferences = context.evidenceReferences.filter(
        (evidence) => evidence.artifactId !== "evidence.conflict.mvcc.3"
      );
      break;
    case "SKELETON_SOURCE_COVERAGE_UNION": {
      const evidence = structuredClone(
        context.evidenceReferences.find((candidate) => (
          candidate.artifactId === "evidence.landscape"
        ))
      );
      evidence.artifactId = "evidence.landscape.uncovered";
      evidence.revisionId = "rev.evidence.landscape.uncovered.1";
      context.evidenceReferences.push(evidence);
      context.skeleton.relations.push({
        relationId: "relation.landscape.consistency-impacts-execution",
        type: "IMPACTS",
        sourceRef: "theme.consistency",
        targetRef: "theme.execution",
        origin: "SOURCE_EXPLICIT",
        riskLevel: "LOW",
        sourceRefs: [evidence.artifactId],
        gapRefs: []
      });
      break;
    }
    case "THEME_SOURCE_COVERAGE_UNION": {
      const evidence = structuredClone(
        context.evidenceReferences.find((candidate) => (
          candidate.artifactId === "evidence.theme.storage"
        ))
      );
      evidence.artifactId = "evidence.theme.storage.uncovered";
      evidence.revisionId = "rev.evidence.theme.storage.uncovered.1";
      context.evidenceReferences.push(evidence);
      context.skeleton.themes[0].relations.push({
        relationId: "relation.theme.storage.locking-impacts-mvcc",
        type: "IMPACTS",
        sourceRef: "module.locking",
        targetRef: "module.mvcc",
        origin: "SOURCE_EXPLICIT",
        riskLevel: "LOW",
        sourceRefs: [evidence.artifactId],
        gapRefs: []
      });
      break;
    }
    default:
      fail("SCHEMA_PARSE_ERROR", `unknown semantic mutation ${mutation}`);
  }
}

const ajv = new Ajv2020({
  allErrors: true,
  strict: false,
  validateFormats: false
});

for (const [schemaId, schema] of schemaDocuments) {
  if (!ajv.validateSchema(schema)) {
    fail("META_SCHEMA_INVALID", `${schemaId}: ${ajv.errorsText(ajv.errors)}`);
  }
  try {
    ajv.addSchema(schema, schemaId);
  } catch (error) {
    fail("UNRESOLVED_LOCAL_REF", `${schemaId}: ${error.message}`);
  }
}

const validators = new Map();
for (const entry of instantiableEntries) {
  try {
    validators.set(entry.id, ajv.getSchema(entry.id));
  } catch (error) {
    fail("UNRESOLVED_LOCAL_REF", `${entry.id}: ${error.message}`);
  }
  if (!validators.get(entry.id)) {
    fail("UNRESOLVED_LOCAL_REF", entry.id);
  }
}

function validateInstance(schemaId, instance, label, shouldPass) {
  const validator = validators.get(schemaId);
  if (!validator) {
    fail("UNRESOLVED_LOCAL_REF", `${label}: ${schemaId}`);
  }
  const valid = validator(instance);
  if (valid !== shouldPass) {
    const detail = ajv.errorsText(validator.errors, {separator: " | "});
    fail(
      "INSTANCE_CONTRACT_VIOLATION",
      shouldPass
        ? `${label} was rejected: ${detail}`
        : `${label} unexpectedly passed`
    );
  }
}

const validFixtures = new Map();
for (const entry of instantiableEntries) {
  if (typeof entry.fixture !== "string") {
    fail("SCHEMA_PARSE_ERROR", `${entry.id} has no fixture`);
  }
  const fixture = readJson(entry.fixture);
  validFixtures.set(entry.id, fixture);
  validateInstance(entry.id, fixture, entry.fixture, true);
}

function cloneFixture(schemaId) {
  return structuredClone(validFixtures.get(schemaId));
}

const skeletonId = "urn:cognitura:schema:cognition:knowledge-skeleton:2.0.0";
const themeId = "urn:cognitura:schema:cognition:knowledge-theme:2.0.0";
const moduleId = "urn:cognitura:schema:cognition:cognitive-module:2.0.0";
const spineId = "urn:cognitura:schema:cognition:primary-cognitive-spine:2.0.0";
const elementId = "urn:cognitura:schema:cognition:knowledge-element:2.0.0";
const evidenceId = "urn:cognitura:schema:cognition:evidence-reference:2.0.0";
const assessmentId = "urn:cognitura:schema:cognition:quality-assessment:2.0.0";

const generatedInvalidCases = [
  {
    name: "knowledge-skeleton-missing-required",
    schemaId: skeletonId,
    mutate(instance) {
      delete instance.themes;
    }
  },
  {
    name: "knowledge-theme-missing-required",
    schemaId: themeId,
    mutate(instance) {
      delete instance.title;
    }
  },
  {
    name: "cognitive-module-missing-required",
    schemaId: moduleId,
    mutate(instance) {
      delete instance.thesis;
    }
  },
  {
    name: "cognitive-module-invalid-relation-type",
    schemaId: moduleId,
    mutate(instance) {
      instance.relations[0].type = "RELATED_TO";
    }
  },
  {
    name: "cognitive-module-published-density",
    schemaId: moduleId,
    mutate(instance) {
      instance.criticalBoundaries = [];
    }
  },
  {
    name: "cognitive-module-published-spine",
    schemaId: moduleId,
    mutate(instance) {
      instance.primaryCognitiveSpine = null;
    }
  },
  {
    name: "cognitive-module-published-source-refs",
    schemaId: moduleId,
    mutate(instance) {
      instance.sourceRefs = [];
    }
  },
  {
    name: "primary-cognitive-spine-missing-required",
    schemaId: spineId,
    mutate(instance) {
      delete instance.moduleRef;
    }
  },
  {
    name: "primary-cognitive-spine-order-type",
    schemaId: spineId,
    mutate(instance) {
      instance.steps[0].order = "1";
    }
  },
  {
    name: "knowledge-element-invalid-element-type",
    schemaId: elementId,
    mutate(instance) {
      instance.elementType = "KNOWLEDGE_CARD";
    }
  },
  {
    name: "theme-closure-missing-required",
    schemaId: "urn:cognitura:schema:cognition:theme-closure:2.0.0",
    mutate(instance) {
      delete instance.themeSpine;
    }
  },
  {
    name: "landscape-closure-missing-required",
    schemaId: "urn:cognitura:schema:cognition:landscape-closure:2.0.0",
    mutate(instance) {
      delete instance.crossThemeSpine;
    }
  },
  {
    name: "evidence-reference-conflict-condition",
    schemaId: evidenceId,
    mutate(instance) {
      instance.conflictState = "UNRESOLVED";
      instance.conflictGroupId = null;
    }
  },
  {
    name: "structure-ambiguity-missing-required",
    schemaId: "urn:cognitura:schema:cognition:structure-ambiguity:2.0.0",
    mutate(instance) {
      delete instance.rationale;
    }
  },
  {
    name: "quality-assessment-published-failure",
    schemaId: assessmentId,
    mutate(instance) {
      instance.hierarchyCorrectness.status = "FAIL";
    }
  }
];

for (const testCase of generatedInvalidCases) {
  const instance = cloneFixture(testCase.schemaId);
  testCase.mutate(instance);
  validateInstance(testCase.schemaId, instance, testCase.name, false);
}

const strictObjectCases = instantiableEntries.filter((entry) => (
  entry.id !== "urn:cognitura:schema:ui:page-state:2.0.0"
));
for (const entry of strictObjectCases) {
  const instance = cloneFixture(entry.id);
  instance.unexpectedContractField = true;
  validateInstance(entry.id, instance, `${entry.id}:unknown-property`, false);
}

const invalidFixtureDirectory = path.join(testDirectory, "fixtures/invalid");
const invalidFixtureNames = fs.readdirSync(invalidFixtureDirectory)
  .filter((name) => name.endsWith(".json"))
  .sort();

for (const fixtureName of invalidFixtureNames) {
  const fixture = readJson(`tests/contracts/schema/fixtures/invalid/${fixtureName}`);
  if (fixture.expectedCategory !== "INSTANCE_CONTRACT_VIOLATION") {
    fail("SCHEMA_PARSE_ERROR", `${fixtureName} has an invalid expectedCategory`);
  }
  validateInstance(fixture.schemaId, fixture.instance, fixtureName, false);
}

const invalidFixtureCount = generatedInvalidCases.length + invalidFixtureNames.length;
if (invalidFixtureCount !== 18) {
  fail("STAGE_EXECUTION_FAILED", `expected 18 invalid fixtures, found ${invalidFixtureCount}`);
}

const actualBaselineSha256 = createHash("sha256")
  .update(fs.readFileSync(path.join(repositoryRoot, "docs/design/cognitura-schema-baseline-2.0.md")))
  .digest("hex");

const constraintKeywords = new Map([
  ["type", "TYPE"],
  ["$ref", "FIELD_REFERENCE"],
  ["required", "REQUIRED"],
  ["enum", "ENUM"],
  ["const", "CONST"],
  ["minItems", "CARDINALITY"],
  ["maxItems", "CARDINALITY"],
  ["uniqueItems", "CARDINALITY"],
  ["minLength", "VALUE_CONSTRAINT"],
  ["maxLength", "VALUE_CONSTRAINT"],
  ["pattern", "VALUE_CONSTRAINT"],
  ["minimum", "VALUE_CONSTRAINT"],
  ["additionalProperties", "STRICTNESS"],
  ["if", "CONDITIONAL"],
  ["then", "CONDITIONAL"],
  ["else", "CONDITIONAL"],
  ["allOf", "CONDITIONAL"],
  ["anyOf", "CONDITIONAL"],
  ["oneOf", "CONDITIONAL"],
  ["not", "CONDITIONAL"],
  ["items", "ITEM_CONTRACT"],
  ["properties", "FIELD_SET"]
]);

const schemaEvidenceSources = new Map([
  [
    "urn:cognitura:schema:cognition:knowledge-skeleton:2.0.0",
    "OD1.2§5-7,§19;RB-003,RB-004,RB-007,RB-008,RB-016,RB-017"
  ],
  [
    "urn:cognitura:schema:cognition:knowledge-theme:2.0.0",
    "OD1.2§5-7,§19;RB-003,RB-004,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:cognitive-module:2.0.0",
    "OD1.2§5-12,§19,§21;RB-003,RB-004,RB-005,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:primary-cognitive-spine:2.0.0",
    "OD1.2§8,§19;RB-003,RB-004,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:knowledge-element:2.0.0",
    "OD1.2§5-12,§19;RB-003,RB-004,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:theme-closure:2.0.0",
    "OD1.2§15,§19;RB-003,RB-004,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:landscape-closure:2.0.0",
    "OD1.2§16,§19;RB-003,RB-004,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:evidence-reference:2.0.0",
    "OD1.2§12-14,§19-20;RB-003,RB-004,RB-007,RB-008,RB-015,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:structure-ambiguity:2.0.0",
    "OD1.2§5-7,§19;RB-003,RB-004,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:cognition:quality-assessment:2.0.0",
    "OD1.2§19,§21;RB-003,RB-004,RB-005,RB-007,RB-008,RB-016"
  ],
  [
    "urn:cognitura:schema:generation:generation-stage-record:2.0.0",
    "OD1.2§17-19;RB-003,RB-004,RB-007,RB-009,RB-016"
  ],
  [
    "urn:cognitura:schema:ui:renderer-input:2.0.0",
    "OD1.2§20.8;RB-003,RB-004,RB-007,RB-010,RB-016"
  ],
  [
    "urn:cognitura:schema:ui:page-state:2.0.0",
    "OD1.2§20.10;RB-007,RB-011"
  ]
]);

const commonDefinitionSources = new Map([
  ["schemaVersion", "RB-004"],
  ["artifactId", "RB-004"],
  ["revisionId", "OD1.2§18;RB-004"],
  ["artifactRef", "RB-008,RB-016"],
  ["artifactRefArray", "RB-008,RB-016"],
  ["nonBlankText", "RB-003"],
  ["sha256", "OD1.2§17;RB-009"],
  ["publicationState", "OD1.2§5-7,§12,§18"],
  ["knowledgeRole", "OD1.2§5-7,§12,§18"],
  ["relationType", "OD1.2§5-7,§12,§18"],
  ["knowledgeElementType", "OD1.2§5-7,§12,§18"],
  ["sourceKind", "OD1.2§20.9"],
  ["assessmentStatus", "OD1.2§21;RB-005"],
  ["conflictState", "OD1.2§14;RB-015"],
  ["riskLevel", "RB-005,RB-008"],
  ["relation", "OD1.2§12;RB-008,RB-016"],
  ["sourceCoverage", "OD1.2§13-14,§19;RB-008,RB-016"],
  ["gap", "OD1.2§13-14,§19;RB-003,RB-008,RB-016"],
  ["criticalBoundary", "OD1.2§9-10,§19;RB-003,RB-008,RB-016"],
  ["evidenceStatement", "OD1.2§9-14,§19;RB-003,RB-008,RB-016"],
  ["conflictResolutionDecision", "OD1.2§14;RB-015,RB-016"],
  ["orderedArtifactStep", "OD1.2§8,§15-16;RB-008,RB-016"],
  ["assessmentFinding", "OD1.2§21;RB-005,RB-008,RB-016"],
  ["assessmentDimension", "OD1.2§21;RB-005"]
]);

const semanticEvidencePolicies = [
  {
    semanticId: "REVISION_CONTEXT_REFERENCE_RESOLUTION",
    schemaId: "urn:cognitura:schema:cognition:common:2.0.0",
    schemaPointer: "/$defs/artifactRef",
    source: "RB-008,RB-016;Cognitura-Schema-Baseline-2.0§5.1",
    reason: "All ArtifactRef values resolve uniquely by target type and owner scope inside one immutable revision context.",
    violationCodes: [
      "ARTIFACT_ID_MISSING",
      "DUPLICATE_ARTIFACT_REVISION",
      "REFERENCE_TARGET_TYPE_MISMATCH",
      "DANGLING_REFERENCE"
    ]
  },
  {
    semanticId: "CANONICAL_HIERARCHY_AND_CANDIDATE_SCOPE",
    schemaId: "urn:cognitura:schema:cognition:cognitive-module:2.0.0",
    schemaPointer: "/properties/primaryParent",
    source: "OD1.2§5-7;RB-016;Cognitura-Schema-Baseline-2.0§6.1-6.3",
    reason: "Themes and Modules preserve the canonical hierarchy, and every Module must resolve from its owning Theme candidate set.",
    violationCodes: [
      "DUPLICATE_THEME_ID",
      "CORE_THEME_OUT_OF_SCOPE",
      "DANGLING_PARENT",
      "DUPLICATE_MODULE_CANDIDATE",
      "CORE_MODULE_OUT_OF_SCOPE",
      "MODULE_NOT_CONFIRMED_CANDIDATE",
      "UNDERSTANDING_ROUTE_OUT_OF_SCOPE"
    ]
  },
  {
    semanticId: "PRIMARY_SPINE_UNIQUENESS_AND_ORDER",
    schemaId: "urn:cognitura:schema:cognition:primary-cognitive-spine:2.0.0",
    schemaPointer: "/properties/steps",
    source: "OD1.2§8;RB-005,RB-016;Cognitura-Schema-Baseline-2.0§6.3-6.4",
    reason: "Each eligible Module resolves its embedded PrimaryCognitiveSpine with unique contiguous cognitive steps.",
    violationCodes: [
      "SPINE_MODULE_MISMATCH",
      "MULTIPLE_PRIMARY_SPINES",
      "DANGLING_MODULE_REF",
      "DUPLICATE_SPINE_STEP_ID",
      "SPINE_ORDER_NOT_CONTIGUOUS"
    ]
  },
  {
    semanticId: "NON_PUBLISHED_MODULE_NULLABILITY",
    schemaId: "urn:cognitura:schema:cognition:cognitive-module:2.0.0",
    schemaPointer: "/properties/primaryCognitiveSpine",
    source: "RB-005;Cognitura-Schema-Baseline-2.0§6.3,§10",
    reason: "Draft and Confirmed Modules may keep spine and quality assessment null without semantic rejection or validator failure.",
    violationCodes: []
  },
  {
    semanticId: "SOURCE_COVERAGE_OWNER_GAP_AND_UNION",
    schemaId: "urn:cognitura:schema:cognition:common:2.0.0",
    schemaPointer: "/$defs/sourceCoverage",
    source: "OD1.2§13-14,§19;RB-016;Cognitura-Schema-Baseline-2.0§5.3",
    reason: "SourceCoverage resolves owner-scoped Evidence and Gaps and exactly preserves all carried Evidence for COMPLETE owners.",
    violationCodes: [
      "DUPLICATE_GAP_ID",
      "DUPLICATE_EVIDENCE_REF",
      "DANGLING_EVIDENCE_REF",
      "EVIDENCE_DOES_NOT_SUPPORT_OWNER",
      "SOURCE_COVERAGE_GAP_MISMATCH",
      "SOURCE_COVERAGE_UNION_MISMATCH"
    ]
  },
  {
    semanticId: "RELATION_OWNER_ENDPOINT_AND_GAP_SCOPE",
    schemaId: "urn:cognitura:schema:cognition:common:2.0.0",
    schemaPointer: "/$defs/relation",
    source: "OD1.2§12;RB-008,RB-016;Cognitura-Schema-Baseline-2.0§5.3,§6.3,§6.5",
    reason: "Relations preserve non-self endpoints, owning-artifact scope, Evidence support, and owner-local Gap references.",
    violationCodes: [
      "DUPLICATE_RELATION_ID",
      "RELATION_SELF_REFERENCE",
      "RELATION_TARGET_OUT_OF_SCOPE",
      "RELATION_GAP_OUT_OF_SCOPE"
    ]
  },
  {
    semanticId: "MODULE_INTERNAL_OWNERSHIP_AND_REFERENCE_SCOPE",
    schemaId: "urn:cognitura:schema:cognition:cognitive-module:2.0.0",
    schemaPointer: "",
    source: "OD1.2§8-12;RB-008,RB-016;Cognitura-Schema-Baseline-2.0§5.3,§6.3,§6.5",
    reason: "Module facets, statements, boundaries, elements, and relation references remain unique and owner-scoped.",
    violationCodes: [
      "DUPLICATE_FACET_ID",
      "DUPLICATE_BOUNDARY_ID",
      "DUPLICATE_STATEMENT_ID",
      "FACET_ELEMENT_OUT_OF_SCOPE",
      "ELEMENT_MODULE_MISMATCH",
      "ELEMENT_RELATION_OUT_OF_SCOPE",
      "STATEMENT_GAP_OUT_OF_SCOPE"
    ]
  },
  {
    semanticId: "THEME_CLOSURE_MODULE_SCOPE_AND_ORDER",
    schemaId: "urn:cognitura:schema:cognition:theme-closure:2.0.0",
    schemaPointer: "/properties/themeSpine",
    source: "OD1.2§15;RB-016;Cognitura-Schema-Baseline-2.0§6.6",
    reason: "ThemeClosure cooperation and spine steps resolve only Modules owned by the current Theme and preserve contiguous order.",
    violationCodes: [
      "DUPLICATE_MODULE_COOPERATION",
      "THEME_CLOSURE_MODULE_OUT_OF_SCOPE"
    ]
  },
  {
    semanticId: "LANDSCAPE_CLOSURE_THEME_ROUTE_AND_ORDER",
    schemaId: "urn:cognitura:schema:cognition:landscape-closure:2.0.0",
    schemaPointer: "/properties/crossThemeSpine",
    source: "OD1.2§16;RB-016;Cognitura-Schema-Baseline-2.0§6.7",
    reason: "LandscapeClosure resolves only local Themes and Modules in its spine and understanding route while preserving order.",
    violationCodes: [
      "DUPLICATE_CORE_THEME",
      "LANDSCAPE_THEME_OUT_OF_SCOPE",
      "LANDSCAPE_ROUTE_OUT_OF_SCOPE"
    ]
  },
  {
    semanticId: "EVIDENCE_EXTERNAL_REFERENCE_TYPES_AND_SUPPORT_SCOPE",
    schemaId: "urn:cognitura:schema:cognition:evidence-reference:2.0.0",
    schemaPointer: "/properties/sourceDocumentRef",
    source: "OD1.2§13-14,§20.9;RB-016;Cognitura-Schema-Baseline-2.0§6.8,§7",
    reason: "Evidence resolves SourceDocument and DocumentBlock references by exact external type and supports only local formal targets.",
    violationCodes: [
      "SOURCE_BLOCK_OUT_OF_CONTEXT",
      "EVIDENCE_SUPPORT_TARGET_MISSING"
    ]
  },
  {
    semanticId: "CONFLICT_MEMBERSHIP_AND_USER_RESOLUTION",
    schemaId: "urn:cognitura:schema:cognition:evidence-reference:2.0.0",
    schemaPointer: "/properties/conflictState",
    source: "OD1.2§14;RB-015,RB-016;Cognitura-Schema-Baseline-2.0§5.3,§6.8",
    reason: "Conflict groups preserve the exact immutable Evidence membership and accept only consistent user resolution decisions.",
    violationCodes: [
      "CONFLICT_MEMBERSHIP_INVALID",
      "CONFLICT_RESOLUTION_NOT_USER",
      "CONFLICT_GROUP_SINGLETON",
      "CONFLICT_SOURCE_HIDDEN",
      "CONFLICT_DECISION_MISMATCH",
      "PREFERRED_EVIDENCE_OUT_OF_GROUP"
    ]
  },
  {
    semanticId: "STRUCTURE_AMBIGUITY_REFERENCE_SCOPE",
    schemaId: "urn:cognitura:schema:cognition:structure-ambiguity:2.0.0",
    schemaPointer: "/properties/locationRef",
    source: "OD1.2§5-7,§19;RB-016;Cognitura-Schema-Baseline-2.0§6.9",
    reason: "StructureAmbiguity location, alternatives, impacts, Evidence, and Gap references resolve inside the current revision context.",
    violationCodes: [
      "DUPLICATE_ALTERNATIVE_ID",
      "AMBIGUITY_GAP_OUT_OF_SCOPE"
    ]
  },
  {
    semanticId: "QUALITY_ASSESSMENT_SUBJECT_AND_FINDING_SCOPE",
    schemaId: "urn:cognitura:schema:cognition:quality-assessment:2.0.0",
    schemaPointer: "/properties/subjectRef",
    source: "OD1.2§21;RB-005,RB-016;Cognitura-Schema-Baseline-2.0§6.10",
    reason: "QualityAssessment targets an allowed formal subject and resolves every finding Artifact and Evidence reference.",
    violationCodes: [
      "QUALITY_SUBJECT_MISMATCH"
    ]
  },
  {
    semanticId: "RENDERER_PROJECTION_SEMANTIC_PRESERVATION",
    schemaId: "urn:cognitura:schema:ui:renderer-input:2.0.0",
    schemaPointer: "",
    source: "OD1.2§20.8;RB-010,RB-016;Cognitura-Schema-Baseline-2.0§8",
    reason: "Renderer projections remain cognitive-only and preserve Module-local endpoints, direction, relation sources, and cognitive order.",
    violationCodes: [
      "DUPLICATE_RENDERER_NODE",
      "DUPLICATE_RENDERER_GROUP",
      "DUPLICATE_RENDERER_RELATION",
      "RENDERER_CONTENT_PATH_UNRESOLVED",
      "RENDERER_CONTENT_PATH_NOT_COGNITIVE",
      "RENDERER_CROSS_MODULE",
      "RENDERER_COGNITIVE_ORDER_CHANGED",
      "RENDERER_GROUP_REF_MISSING",
      "RENDERER_SOURCE_OUT_OF_SCOPE",
      "RENDERER_NODE_REF_MISSING",
      "RENDERER_RELATION_OUT_OF_SCOPE",
      "RENDERER_RELATION_TYPE_CHANGED",
      "RENDERER_RELATION_ENDPOINT_CHANGED",
      "RENDERER_RELATION_SOURCE_CHANGED",
      "RENDERER_GAP_OUT_OF_SCOPE",
      "RENDERER_DENSITY_GROUPING_INVALID"
    ]
  },
  {
    semanticId: "GENERATION_SOURCE_OUTPUT_RETRY_AND_DEDUPLICATION",
    schemaId: "urn:cognitura:schema:generation:generation-stage-record:2.0.0",
    schemaPointer: "",
    source: "OD1.2§17-19;RB-009,RB-016;Cognitura-Schema-Baseline-2.0§7",
    reason: "Generation records resolve typed source blocks and retry scopes, validate cognitive outputs, and reject duplicate successful runs.",
    violationCodes: [
      "GENERATION_OUTPUT_SCHEMA_INVALID",
      "GENERATION_OUTPUT_CONTRACT_VIOLATION",
      "DUPLICATE_SUCCESSFUL_RUN"
    ]
  },
  {
    semanticId: "SEMANTIC_ERROR_CLASSIFICATION_STABILITY",
    schemaId: "urn:cognitura:schema:cognition:common:2.0.0",
    schemaPointer: "",
    source: "RB-014;Cognitura-Schema-Baseline-2.0§11",
    reason: "Every semantic negative exits through a stable asserted SemanticViolation code rather than an unclassified runtime failure.",
    violationCodes: []
  }
].map((policy) => ({
  ...policy,
  constraintKinds: ["SEMANTIC_INVARIANT"],
  evidenceKind: policy.source.includes("OD1.2§")
    ? "OVERALL_DESIGN_EVIDENCE"
    : "REBASELINE_DECISION"
}));

semanticEvidenceByViolationCode = new Map();
for (const policy of semanticEvidencePolicies) {
  for (const code of policy.violationCodes) {
    if (semanticEvidenceByViolationCode.has(code)) {
      fail(
        "EVIDENCE_MAPPING_MISSING",
        `runtime semantic violation code ${code} has multiple evidence policies`
      );
    }
    semanticEvidenceByViolationCode.set(code, policy.semanticId);
  }
}

class EvidenceMapViolation extends Error {
  constructor(message) {
    super(message);
    this.name = "EvidenceMapViolation";
  }
}

function evidenceAssert(condition, message) {
  if (!condition) {
    throw new EvidenceMapViolation(message);
  }
}

function evidenceSourceFor(schemaId, pointer) {
  if (pointer === "/$schema") {
    return "RB-001";
  }
  if (pointer === "/$id") {
    return "RB-006";
  }
  if (schemaId === "urn:cognitura:schema:cognition:common:2.0.0") {
    const definitionMatch = /^\/\$defs\/([^/]+)/.exec(pointer);
    if (definitionMatch) {
      return commonDefinitionSources.get(definitionMatch[1]) ??
        "RB-003,RB-004,RB-007,RB-008,RB-015,RB-016";
    }
    return "RB-003,RB-004,RB-007,RB-008,RB-015,RB-016";
  }
  return schemaEvidenceSources.get(schemaId);
}

function evidencePolicy(schemaId, pointer, constraintKinds) {
  const source = evidenceSourceFor(schemaId, pointer);
  evidenceAssert(source, `no evidence policy for ${schemaId}${pointer}`);
  const schemaName = schemaId
    .replace("urn:cognitura:schema:", "")
    .replace(":2.0.0", "");
  const pointerLabel = pointer === "" ? "/" : pointer;
  const constraintSummary = constraintKinds.length === 0
    ? "FIELD_DECLARATION"
    : constraintKinds.join(",");
  return {
    evidenceKind: source.includes("OD1.2§")
      ? "OVERALL_DESIGN_EVIDENCE"
      : "REBASELINE_DECISION",
    source,
    reason: `${schemaName}${pointerLabel} enforces ${constraintSummary} from ${source}.`
  };
}

function collectExpectedEvidenceEntries() {
  const expectedEntries = new Map();
  for (const [schemaId, schema] of schemaDocuments) {
    walk(schema, (value, pointer) => {
      if (pointer === "/$schema" || pointer === "/$id") {
        const constraintKinds = [
          pointer === "/$schema" ? "SCHEMA_DIALECT" : "SCHEMA_IDENTITY"
        ];
        const key = `${schemaId}\n${pointer}`;
        expectedEntries.set(key, {
          schemaId,
          schemaPointer: pointer,
          constraintKinds,
          ...evidencePolicy(schemaId, pointer, constraintKinds)
        });
        return;
      }
      if (!value || Array.isArray(value) || typeof value !== "object") {
        return;
      }
      const constraintKinds = [];
      for (const keyword of Object.keys(value)) {
        const kind = constraintKeywords.get(keyword);
        if (kind && !constraintKinds.includes(kind)) {
          constraintKinds.push(kind);
        }
      }
      const isFieldNode = (
        /\/properties\/[^/]+$/.test(pointer) ||
        /^\/\$defs\/[^/]+$/.test(pointer)
      );
      if (constraintKinds.length === 0 && !isFieldNode) {
        return;
      }
      constraintKinds.sort();
      const key = `${schemaId}\n${pointer}`;
      const policy = evidencePolicy(schemaId, pointer, constraintKinds);
      expectedEntries.set(key, {
        schemaId,
        schemaPointer: pointer,
        constraintKinds,
        ...policy
      });
    });
  }
  return expectedEntries;
}

function buildExpectedEvidenceMapDocument() {
  return {
    baseline: "Cognitura-Schema-Baseline-2.0",
    baselineSha256: actualBaselineSha256,
    entries: [...collectExpectedEvidenceEntries().values()],
    semanticEntries: structuredClone(semanticEvidencePolicies)
  };
}

const expectedEvidenceMap = buildExpectedEvidenceMapDocument();
if (process.argv.includes("--render-evidence-map")) {
  process.stdout.write(`${JSON.stringify(expectedEvidenceMap, null, 2)}\n`);
  process.exit(0);
}
const evidenceMapPageArgument = process.argv.find((argument) => (
  argument.startsWith("--render-evidence-map-page=")
));
if (evidenceMapPageArgument) {
  const page = Number(evidenceMapPageArgument.split("=")[1]);
  const pageSize = 40;
  process.stdout.write(`${JSON.stringify({
    baseline: expectedEvidenceMap.baseline,
    baselineSha256: expectedEvidenceMap.baselineSha256,
    entries: expectedEvidenceMap.entries.slice(page * pageSize, (page + 1) * pageSize),
    semanticEntries: page === 0 ? expectedEvidenceMap.semanticEntries : []
  })}\n`);
  process.exit(0);
}

function validateEvidenceMapDocument(document) {
  evidenceAssert(
    document.baseline === "Cognitura-Schema-Baseline-2.0" &&
    document.baselineSha256 === actualBaselineSha256,
    "evidence map baseline identity is invalid"
  );
  evidenceAssert(
    Array.isArray(document.entries) && document.entries.length > 0,
    "evidence map has no entries"
  );
  evidenceAssert(
    Array.isArray(document.semanticEntries) && document.semanticEntries.length > 0,
    "evidence map has no semantic invariant entries"
  );

  const expectedEntries = collectExpectedEvidenceEntries();
  const actualEntries = new Map();
  for (const entry of document.entries) {
    evidenceAssert(
      typeof entry.schemaId === "string" &&
      typeof entry.schemaPointer === "string" &&
      Array.isArray(entry.constraintKinds) &&
      uniqueValues(entry.constraintKinds) &&
      ["OVERALL_DESIGN_EVIDENCE", "REBASELINE_DECISION"].includes(entry.evidenceKind) &&
      typeof entry.source === "string" &&
      entry.source.length > 0 &&
      typeof entry.reason === "string" &&
      entry.reason.length > 0,
      "evidence map contains a malformed entry"
    );
    const mappedSchema = schemaDocuments.get(entry.schemaId);
    evidenceAssert(mappedSchema, `unknown Schema ID ${entry.schemaId}`);
    evidenceAssert(
      resolveJsonPointer(mappedSchema, entry.schemaPointer).found,
      `${entry.schemaId}${entry.schemaPointer} does not resolve`
    );
    const key = `${entry.schemaId}\n${entry.schemaPointer}`;
    evidenceAssert(
      !actualEntries.has(key),
      `duplicate evidence entry ${entry.schemaId}${entry.schemaPointer}`
    );
    const expected = expectedEntries.get(key);
    evidenceAssert(
      expected,
      `unexpected evidence entry ${entry.schemaId}${entry.schemaPointer}`
    );
    evidenceAssert(
      equalSets(entry.constraintKinds, expected.constraintKinds),
      `constraint kinds differ at ${entry.schemaId}${entry.schemaPointer}`
    );
    evidenceAssert(
      entry.evidenceKind === expected.evidenceKind &&
      entry.source === expected.source &&
      entry.reason === expected.reason,
      `evidence policy differs at ${entry.schemaId}${entry.schemaPointer}`
    );
    actualEntries.set(key, entry);
  }

  evidenceAssert(
    actualEntries.size === expectedEntries.size,
    `expected ${expectedEntries.size} exact evidence entries, found ${actualEntries.size}`
  );
  for (const key of expectedEntries.keys()) {
    evidenceAssert(actualEntries.has(key), `missing exact evidence entry ${key}`);
  }

  const expectedSemanticEntries = new Map(
    semanticEvidencePolicies.map((entry) => [entry.semanticId, entry])
  );
  const actualSemanticEntries = new Map();
  for (const entry of document.semanticEntries) {
    evidenceAssert(
      typeof entry.semanticId === "string" &&
      typeof entry.schemaId === "string" &&
      typeof entry.schemaPointer === "string" &&
      Array.isArray(entry.constraintKinds) &&
      uniqueValues(entry.constraintKinds) &&
      Array.isArray(entry.violationCodes) &&
      uniqueValues(entry.violationCodes) &&
      ["OVERALL_DESIGN_EVIDENCE", "REBASELINE_DECISION"].includes(entry.evidenceKind) &&
      typeof entry.source === "string" &&
      entry.source.length > 0 &&
      typeof entry.reason === "string" &&
      entry.reason.length > 0,
      "evidence map contains a malformed semantic invariant entry"
    );
    const mappedSchema = schemaDocuments.get(entry.schemaId);
    evidenceAssert(mappedSchema, `unknown semantic Schema ID ${entry.schemaId}`);
    evidenceAssert(
      resolveJsonPointer(mappedSchema, entry.schemaPointer).found,
      `${entry.semanticId} points to an unresolved Schema location`
    );
    evidenceAssert(
      !actualSemanticEntries.has(entry.semanticId),
      `duplicate semantic evidence entry ${entry.semanticId}`
    );
    const expected = expectedSemanticEntries.get(entry.semanticId);
    evidenceAssert(expected, `unexpected semantic evidence entry ${entry.semanticId}`);
    evidenceAssert(
      entry.schemaId === expected.schemaId &&
      entry.schemaPointer === expected.schemaPointer &&
      equalSets(entry.constraintKinds, expected.constraintKinds) &&
      equalSets(entry.violationCodes, expected.violationCodes) &&
      entry.evidenceKind === expected.evidenceKind &&
      entry.source === expected.source &&
      entry.reason === expected.reason,
      `semantic evidence policy differs at ${entry.semanticId}`
    );
    actualSemanticEntries.set(entry.semanticId, entry);
  }
  evidenceAssert(
    actualSemanticEntries.size === expectedSemanticEntries.size,
    `expected ${expectedSemanticEntries.size} semantic evidence entries, found ${actualSemanticEntries.size}`
  );
  for (const semanticId of expectedSemanticEntries.keys()) {
    evidenceAssert(
      actualSemanticEntries.has(semanticId),
      `missing semantic evidence entry ${semanticId}`
    );
  }

  return {
    schemaEntryCount: actualEntries.size,
    semanticEntryCount: actualSemanticEntries.size,
    totalEntryCount: actualEntries.size + actualSemanticEntries.size
  };
}

const evidenceMap = readJson("schemas/evidence-map.json");
let evidenceMapCounts;
try {
  evidenceMapCounts = validateEvidenceMapDocument(evidenceMap);
} catch (error) {
  if (error instanceof EvidenceMapViolation) {
    fail("EVIDENCE_MAPPING_MISSING", error.message);
  }
  throw error;
}

const evidenceMapNegativeCases = [
  {
    name: "wrong-common-source-kind-policy",
    mutate(document) {
      const entry = document.entries.find((candidate) => (
        candidate.schemaId === "urn:cognitura:schema:cognition:common:2.0.0" &&
        candidate.schemaPointer === "/$defs/sourceKind"
      ));
      entry.evidenceKind = "REBASELINE_DECISION";
      entry.source = "RB-003";
    }
  },
  {
    name: "generic-reason",
    mutate(document) {
      document.entries[0].reason = "Approved baseline node.";
    }
  },
  {
    name: "ancestor-fallback",
    mutate(document) {
      const index = document.entries.findIndex((entry) => (
        entry.schemaPointer.includes("/then/properties/")
      ));
      document.entries.splice(index, 1);
    }
  },
  {
    name: "schema-identity-missing",
    mutate(document) {
      const index = document.entries.findIndex((entry) => (
        entry.schemaPointer === "/$id"
      ));
      document.entries.splice(index, 1);
    }
  },
  {
    name: "semantic-invariant-missing",
    mutate(document) {
      document.semanticEntries.splice(0, 1);
    }
  },
  {
    name: "semantic-violation-code-missing",
    mutate(document) {
      const entry = document.semanticEntries.find((candidate) => (
        candidate.violationCodes.length > 0
      ));
      entry.violationCodes.splice(0, 1);
    }
  }
];

for (const testCase of evidenceMapNegativeCases) {
  const mutated = structuredClone(evidenceMap);
  testCase.mutate(mutated);
  let rejected = false;
  try {
    validateEvidenceMapDocument(mutated);
  } catch (error) {
    if (!(error instanceof EvidenceMapViolation)) {
      throw error;
    }
    rejected = true;
  }
  if (!rejected) {
    fail("EVIDENCE_MAPPING_MISSING", `${testCase.name} unexpectedly passed`);
  }
}

const validSemanticContext = readJson(
  "tests/contracts/schema/fixtures/semantic/valid-context.json"
);

for (const [schemaId, instances] of [
  [skeletonId, [validSemanticContext.skeleton]],
  [moduleId, validSemanticContext.modules],
  ["urn:cognitura:schema:cognition:theme-closure:2.0.0", validSemanticContext.themeClosures],
  ["urn:cognitura:schema:cognition:landscape-closure:2.0.0", validSemanticContext.landscapeClosures],
  ["urn:cognitura:schema:cognition:structure-ambiguity:2.0.0", validSemanticContext.structureAmbiguities],
  [evidenceId, validSemanticContext.evidenceReferences],
  ["urn:cognitura:schema:generation:generation-stage-record:2.0.0", validSemanticContext.generationRecords],
  ["urn:cognitura:schema:ui:renderer-input:2.0.0", validSemanticContext.rendererInputs]
]) {
  instances.forEach((instance, index) => (
    validateInstance(schemaId, instance, `valid-context:${schemaId}:${index}`, true)
  ));
}

const draftNullModule = validSemanticContext.modules.find((module) => (
  module.publicationState === "DRAFT" &&
  module.primaryCognitiveSpine === null &&
  module.qualityAssessment === null
));
if (!draftNullModule) {
  fail("STAGE_EXECUTION_FAILED", "valid context has no legal Draft null Module");
}

const confirmedSemanticContext = structuredClone(validSemanticContext);
const confirmedNullModule = confirmedSemanticContext.modules.find((module) => (
  module.artifactId === draftNullModule.artifactId
));
confirmedNullModule.publicationState = "CONFIRMED";
for (const element of confirmedNullModule.knowledgeElements) {
  element.publicationState = "CONFIRMED";
}
validateInstance(
  moduleId,
  confirmedNullModule,
  "valid-context:confirmed-null-module",
  true
);

const semanticValidContexts = [
  {label: "draft-null-module", context: validSemanticContext},
  {label: "confirmed-null-module", context: confirmedSemanticContext}
];
for (const semanticContext of semanticValidContexts) {
  try {
    validateSemanticContext(semanticContext.context);
  } catch (error) {
    if (error instanceof SemanticViolation) {
      fail(
        "SEMANTIC_REFERENCE_VIOLATION",
        `${semanticContext.label}: ${error.code}: ${error.message}`
      );
    }
    throw error;
  }
}

const semanticDirectory = path.join(testDirectory, "fixtures/semantic");
const semanticCaseNames = fs.readdirSync(semanticDirectory)
  .filter((name) => name.endsWith(".json") && name !== "valid-context.json")
  .sort();

for (const caseName of semanticCaseNames) {
  const testCase = readJson(`tests/contracts/schema/fixtures/semantic/${caseName}`);
  if (testCase.expectedCategory !== "SEMANTIC_REFERENCE_VIOLATION") {
    fail("SCHEMA_PARSE_ERROR", `${caseName} has an invalid expectedCategory`);
  }
  const context = structuredClone(validSemanticContext);
  applySemanticMutation(context, testCase.mutation);
  try {
    validateSemanticContext(context);
    fail("SEMANTIC_REFERENCE_VIOLATION", `${caseName} unexpectedly passed`);
  } catch (error) {
    if (!(error instanceof SemanticViolation)) {
      throw error;
    }
    if (error.code !== testCase.expectedCode) {
      fail(
        "SEMANTIC_REFERENCE_VIOLATION",
        `${caseName} expected ${testCase.expectedCode}, got ${error.code}: ${error.message}`
      );
    }
  }
}

if (semanticCaseNames.length !== 34) {
  fail("STAGE_EXECUTION_FAILED", `expected 34 semantic negative cases, found ${semanticCaseNames.length}`);
}

process.stdout.write([
  "JsonSchemaValidation = PASS",
  `SchemaDocumentCount = ${catalog.schemas.length}`,
  `InstantiableSchemaCount = ${instantiableEntries.length}`,
  `ValidFixtureCount = ${validFixtures.size}`,
  `InvalidFixtureCount = ${invalidFixtureCount}`,
  `StrictObjectNegativeCaseCount = ${strictObjectCases.length}`,
  `SemanticValidContextCount = ${semanticValidContexts.length}`,
  "NonPublishedModuleNullability = PASS",
  `SemanticNegativeCaseCount = ${semanticCaseNames.length}`,
  `SemanticViolationCodeCount = ${semanticEvidenceByViolationCode.size}`,
  `EvidenceMapSchemaEntryCount = ${evidenceMapCounts.schemaEntryCount}`,
  `EvidenceMapSemanticEntryCount = ${evidenceMapCounts.semanticEntryCount}`,
  `EvidenceMapEntryCount = ${evidenceMapCounts.totalEntryCount}`,
  `EvidenceMapNegativeCaseCount = ${evidenceMapNegativeCases.length}`,
  "EvidenceMapValidation = PASS",
  "NetworkResolution = FORBIDDEN",
  "W0-G3 JsonSchemaValidation = PASS"
].join("\n") + "\n");
