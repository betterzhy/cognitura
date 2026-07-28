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

function semanticAssert(condition, code, message) {
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
  const artifactRevisions = new Map();
  const candidateIds = new Set();
  const externalRefs = new Set(context.externalRefs ?? []);

  function registerArtifact(type, artifact) {
    semanticAssert(
      artifact && typeof artifact.artifactId === "string",
      "ARTIFACT_ID_MISSING",
      `${type} has no artifactId`
    );
    const existingRevision = artifactRevisions.get(artifact.artifactId);
    semanticAssert(
      existingRevision === undefined,
      "DUPLICATE_ARTIFACT_REVISION",
      `${artifact.artifactId} appears more than once in one revision context`
    );
    artifactRevisions.set(artifact.artifactId, artifact.revisionId);
    artifacts.set(artifact.artifactId, {type, artifact});
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

  const getArtifact = (artifactId, expectedTypes, code = "DANGLING_REFERENCE") => {
    const record = artifacts.get(artifactId);
    semanticAssert(record, code, artifactId);
    if (expectedTypes) {
      semanticAssert(
        expectedTypes.includes(record.type),
        "REFERENCE_TARGET_TYPE_MISMATCH",
        `${artifactId} is ${record.type}, expected ${expectedTypes.join("/")}`
      );
    }
    return record.artifact;
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
  for (const module of context.modules) {
    semanticAssert(
      themeIds.has(module.primaryParent),
      "DANGLING_PARENT",
      `${module.artifactId} -> ${module.primaryParent}`
    );
  }

  const allSpines = [
    ...context.modules.flatMap((module) => (
      module.primaryCognitiveSpine === null ? [] : [module.primaryCognitiveSpine]
    )),
    ...(context.additionalSpines ?? [])
  ];
  for (const module of context.modules) {
    const moduleSpines = allSpines.filter((spine) => spine.moduleRef === module.artifactId);
    semanticAssert(
      moduleSpines.length === 1,
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

  const evidenceById = new Map(
    context.evidenceReferences.map((evidence) => [evidence.artifactId, evidence])
  );
  const gapOwners = new Map();
  const globalGapIds = new Set();

  function registerGaps(ownerId, gaps) {
    const ids = gaps.map((gap) => gap.gapId);
    semanticAssert(uniqueValues(ids), "DUPLICATE_GAP_ID", ownerId);
    for (const gapId of ids) {
      globalGapIds.add(gapId);
    }
    gapOwners.set(ownerId, new Set(ids));
  }

  function checkEvidenceRefs(sourceRefs, ownerId) {
    semanticAssert(uniqueValues(sourceRefs), "DUPLICATE_EVIDENCE_REF", ownerId);
    for (const sourceRef of sourceRefs) {
      semanticAssert(evidenceById.has(sourceRef), "DANGLING_EVIDENCE_REF", sourceRef);
    }
  }

  function checkSourceCoverage(ownerId, sourceCoverage, gaps) {
    registerGaps(ownerId, gaps);
    semanticAssert(
      equalSets(sourceCoverage.gapRefs, gaps.map((gap) => gap.gapId)),
      "SOURCE_COVERAGE_GAP_MISMATCH",
      ownerId
    );
    checkEvidenceRefs(sourceCoverage.evidenceRefs, ownerId);
    for (const evidenceRef of sourceCoverage.evidenceRefs) {
      semanticAssert(
        evidenceById.get(evidenceRef).supports.includes(ownerId),
        "EVIDENCE_DOES_NOT_SUPPORT_OWNER",
        `${evidenceRef} does not support ${ownerId}`
      );
    }
  }

  for (const module of context.modules) {
    const relations = new Map();
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
      getArtifact(relation.sourceRef, ["KnowledgeElement"]);
      getArtifact(relation.targetRef, ["KnowledgeElement"]);
      checkEvidenceRefs(relation.sourceRefs, module.artifactId);
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
      }
    }
    checkEvidenceRefs(module.sourceRefs, module.artifactId);
    registerGaps(module.artifactId, module.gaps);
    semanticAssert(
      module.qualityAssessment.subjectRef === module.artifactId,
      "QUALITY_SUBJECT_MISMATCH",
      module.artifactId
    );
  }

  checkSourceCoverage(skeleton.artifactId, skeleton.sourceCoverage, skeleton.gaps);
  for (const theme of skeleton.themes) {
    checkSourceCoverage(theme.artifactId, theme.sourceCoverage, theme.gaps);
    for (const candidate of theme.moduleCandidates) {
      checkSourceCoverage(candidate.moduleId, candidate.sourceCoverage, candidate.gaps);
    }
  }

  function checkScopedRelations(ownerId, relations, allowedRefs) {
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
      semanticAssert(
        relation.gapRefs.every((gapRef) => globalGapIds.has(gapRef)),
        "RELATION_GAP_OUT_OF_SCOPE",
        relation.relationId
      );
    }
  }

  checkScopedRelations(skeleton.artifactId, skeleton.relations, themeIds);
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
      theme.relations,
      new Set(theme.moduleCandidates.map((candidate) => candidate.moduleId))
    );
  }

  for (const closure of context.themeClosures) {
    getArtifact(closure.themeRef, ["KnowledgeTheme"]);
    checkSourceCoverage(closure.artifactId, closure.sourceCoverage, closure.gaps);
    assertUniqueField(
      closure.moduleCooperation,
      "moduleRef",
      "DUPLICATE_MODULE_COOPERATION",
      closure.artifactId
    );
    assertUniqueField(closure.themeSpine, "stepId", "DUPLICATE_SPINE_STEP_ID", closure.artifactId);
    assertUniqueField(
      closure.criticalDistinctions,
      "statementId",
      "DUPLICATE_STATEMENT_ID",
      closure.artifactId
    );
    assertUniqueField(closure.boundaries, "statementId", "DUPLICATE_STATEMENT_ID", closure.artifactId);
    checkScopedRelations(closure.artifactId, closure.relatedThemes, themeIds);
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
    checkSourceCoverage(closure.artifactId, closure.sourceCoverage, closure.gaps);
    assertUniqueField(closure.coreThemes, "themeRef", "DUPLICATE_CORE_THEME", closure.artifactId);
    assertUniqueField(
      closure.crossThemeSpine,
      "stepId",
      "DUPLICATE_SPINE_STEP_ID",
      closure.artifactId
    );
    assertUniqueField(
      closure.globalBoundaries,
      "statementId",
      "DUPLICATE_STATEMENT_ID",
      closure.artifactId
    );
    checkScopedRelations(closure.artifactId, closure.keyDependencies, themeIds);
    for (const coreTheme of closure.coreThemes) {
      getArtifact(coreTheme.themeRef, ["KnowledgeTheme"]);
    }
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
    semanticAssert(
      externalRefs.has(evidence.sourceDocumentRef) && externalRefs.has(evidence.documentBlockRef),
      "SOURCE_BLOCK_OUT_OF_CONTEXT",
      evidence.artifactId
    );
    for (const supportedRef of evidence.supports) {
      semanticAssert(supportedTargets.has(supportedRef), "EVIDENCE_SUPPORT_TARGET_MISSING", supportedRef);
    }
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

  for (const ambiguity of context.structureAmbiguities) {
    getArtifact(ambiguity.locationRef, ["KnowledgeTheme", "CognitiveModule", "KnowledgeElement"]);
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
    semanticAssert(
      ambiguity.gapRefs.every((gapRef) => globalGapIds.has(gapRef)),
      "AMBIGUITY_GAP_OUT_OF_SCOPE",
      ambiguity.artifactId
    );
  }

  for (const renderer of context.rendererInputs) {
    const module = getArtifact(renderer.moduleRef, ["CognitiveModule"]);
    const nodeIds = new Set(renderer.nodes.map((node) => node.nodeId));
    const groupIds = new Set(renderer.groups.map((group) => group.groupId));
    semanticAssert(nodeIds.size === renderer.nodes.length, "DUPLICATE_RENDERER_NODE", renderer.moduleRef);
    semanticAssert(groupIds.size === renderer.groups.length, "DUPLICATE_RENDERER_GROUP", renderer.moduleRef);
    for (const node of renderer.nodes) {
      semanticAssert(
        node.artifactRef === renderer.moduleRef,
        "RENDERER_CROSS_MODULE",
        node.nodeId
      );
      semanticAssert(
        resolveJsonPointer(module, node.contentPath).found,
        "RENDERER_CONTENT_PATH_UNRESOLVED",
        node.contentPath
      );
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
      semanticAssert(
        moduleRelations.get(relation.artifactRelationRef).type === relation.type,
        "RENDERER_RELATION_TYPE_CHANGED",
        relation.relationId
      );
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
        (gapOwners.get(module.artifactId) ?? new Set()).has(gapRef)
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
      semanticAssert(externalRefs.has(sourceBlockRef), "SOURCE_BLOCK_OUT_OF_CONTEXT", sourceBlockRef);
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

const evidenceMap = readJson("schemas/evidence-map.json");
const actualBaselineSha256 = createHash("sha256")
  .update(fs.readFileSync(path.join(repositoryRoot, "docs/design/cognitura-schema-baseline-2.0.md")))
  .digest("hex");
if (
  evidenceMap.baseline !== "Cognitura-Schema-Baseline-2.0" ||
  evidenceMap.baselineSha256 !== actualBaselineSha256
) {
  fail("EVIDENCE_MAPPING_MISSING", "evidence map baseline identity is invalid");
}
if (!Array.isArray(evidenceMap.entries) || evidenceMap.entries.length === 0) {
  fail("EVIDENCE_MAPPING_MISSING", "schemas/evidence-map.json has no entries");
}

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

const evidenceIndex = new Map();
const evidenceBySchema = new Map();
for (const entry of evidenceMap.entries) {
  if (
    typeof entry.schemaId !== "string" ||
    typeof entry.schemaPointer !== "string" ||
    !Array.isArray(entry.constraintKinds) ||
    !["OVERALL_DESIGN_EVIDENCE", "REBASELINE_DECISION"].includes(entry.evidenceKind) ||
    typeof entry.source !== "string" ||
    entry.source.length === 0 ||
    typeof entry.reason !== "string" ||
    entry.reason.length === 0
  ) {
    fail("EVIDENCE_MAPPING_MISSING", "evidence map contains a malformed entry");
  }
  const mappedSchema = schemaDocuments.get(entry.schemaId);
  if (!mappedSchema) {
    fail("EVIDENCE_MAPPING_MISSING", `unknown Schema ID ${entry.schemaId}`);
  }
  if (!resolveJsonPointer(mappedSchema, entry.schemaPointer).found) {
    fail(
      "EVIDENCE_MAPPING_MISSING",
      `${entry.schemaId}${entry.schemaPointer} does not resolve`
    );
  }
  const key = `${entry.schemaId}\n${entry.schemaPointer}`;
  if (evidenceIndex.has(key)) {
    fail("EVIDENCE_MAPPING_MISSING", `duplicate evidence entry ${entry.schemaId}${entry.schemaPointer}`);
  }
  const indexedEntry = {
    pointer: entry.schemaPointer,
    kinds: new Set(entry.constraintKinds)
  };
  evidenceIndex.set(key, indexedEntry.kinds);
  const schemaEntries = evidenceBySchema.get(entry.schemaId) ?? [];
  schemaEntries.push(indexedEntry);
  evidenceBySchema.set(entry.schemaId, schemaEntries);
}

for (const [schemaId, schema] of schemaDocuments) {
  walk(schema, (value, pointer) => {
    if (!value || Array.isArray(value) || typeof value !== "object") {
      return;
    }
    const requiredKinds = new Set();
    for (const keyword of Object.keys(value)) {
      const kind = constraintKeywords.get(keyword);
      if (kind) {
        requiredKinds.add(kind);
      }
    }
    if (requiredKinds.size === 0) {
      return;
    }
    const candidates = (evidenceBySchema.get(schemaId) ?? [])
      .filter((entry) => (
        entry.pointer === pointer ||
        entry.pointer === "" ||
        pointer.startsWith(`${entry.pointer}/`)
      ))
      .sort((left, right) => right.pointer.length - left.pointer.length);
    const mappedKinds = candidates.find((entry) => (
      [...requiredKinds].every((kind) => entry.kinds.has(kind))
    ))?.kinds;
    if (!mappedKinds) {
      fail("EVIDENCE_MAPPING_MISSING", `${schemaId}${pointer}`);
    }
  });

  walk(schema, (value, pointer) => {
    if (!value || Array.isArray(value) || typeof value !== "object") {
      return;
    }
    if (
      /\/properties\/[^/]+$/.test(pointer) ||
      /^\/\$defs\/[^/]+$/.test(pointer)
    ) {
      if (!evidenceIndex.has(`${schemaId}\n${pointer}`)) {
        fail("EVIDENCE_MAPPING_MISSING", `${schemaId}${pointer} has no field-level entry`);
      }
    }
  });
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

try {
  validateSemanticContext(validSemanticContext);
} catch (error) {
  if (error instanceof SemanticViolation) {
    fail("SEMANTIC_REFERENCE_VIOLATION", `${error.code}: ${error.message}`);
  }
  throw error;
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

if (semanticCaseNames.length !== 12) {
  fail("STAGE_EXECUTION_FAILED", `expected 12 semantic negative cases, found ${semanticCaseNames.length}`);
}

process.stdout.write([
  "JsonSchemaValidation = PASS",
  `SchemaDocumentCount = ${catalog.schemas.length}`,
  `InstantiableSchemaCount = ${instantiableEntries.length}`,
  `ValidFixtureCount = ${validFixtures.size}`,
  `InvalidFixtureCount = ${invalidFixtureCount}`,
  `StrictObjectNegativeCaseCount = ${strictObjectCases.length}`,
  `SemanticNegativeCaseCount = ${semanticCaseNames.length}`,
  `EvidenceMapEntryCount = ${evidenceMap.entries.length}`,
  "EvidenceMapValidation = PASS",
  "NetworkResolution = FORBIDDEN",
  "W0-G3 JsonSchemaValidation = PASS"
].join("\n") + "\n");
