import { describe, expect, it } from "vitest";

import type {
  CognitiveModule,
  PrimaryCognitiveSpineStep,
} from "./model";
import { projectModuleNarrative } from "./projectModuleNarrative";

const sourceRef = "evidence.mvcc";

const schemaValidSteps: readonly PrimaryCognitiveSpineStep[] = [
  {
    stepId: "spine-step.mvcc.1",
    order: 1,
    statement: "Create a version.",
    sourceRefs: [sourceRef],
  },
  {
    stepId: "spine-step.mvcc.2",
    order: 2,
    statement: "Capture a visibility boundary.",
    sourceRefs: [sourceRef],
  },
  {
    stepId: "spine-step.mvcc.3",
    order: 3,
    statement: "Select a visible version.",
    sourceRefs: [sourceRef],
  },
  {
    stepId: "spine-step.mvcc.4",
    order: 4,
    statement: "Retire obsolete versions.",
    sourceRefs: [sourceRef],
  },
];

const schemaValidModule: CognitiveModule = {
  schemaVersion: "2.0.0",
  artifactId: "module.mvcc",
  revisionId: "rev.module.mvcc.1",
  publicationState: "PUBLISHED",
  primaryParent: "theme.storage",
  title: "MVCC",
  thesis: "MVCC coordinates readers and writers.",
  role: "CORE",
  coreQuestions: ["How does a read choose a visible version?"],
  primaryCognitiveSpine: {
    schemaVersion: "2.0.0",
    artifactId: "spine.mvcc",
    revisionId: "rev.spine.mvcc.1",
    publicationState: "PUBLISHED",
    moduleRef: "module.mvcc",
    steps: schemaValidSteps,
  },
  facets: [
    {
      facetId: "facet.visibility",
      title: "Visibility",
      summary: "Rules for selecting record versions.",
      elementRefs: ["element.visibility", "element.version"],
      sourceRefs: [sourceRef],
    },
  ],
  knowledgeElements: [
    {
      schemaVersion: "2.0.0",
      artifactId: "element.visibility",
      revisionId: "rev.element.visibility.1",
      publicationState: "PUBLISHED",
      moduleRef: "module.mvcc",
      elementType: "MECHANISM",
      title: "Visibility judgment",
      content: "A read view selects the newest visible record version.",
      sourceRefs: [sourceRef],
      relations: ["relation.visibility.depends-version"],
    },
  ],
  keyTakeaways: [
    {
      statementId: "takeaway.mvcc.1",
      statement: "Visibility depends on transaction boundaries.",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
    {
      statementId: "takeaway.mvcc.2",
      statement: "Record versions decouple reads from current writes.",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
    {
      statementId: "takeaway.mvcc.3",
      statement: "Cleanup depends on active visibility windows.",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
  ],
  criticalBoundaries: [
    {
      boundaryId: "boundary.mvcc.1",
      statement: "Visibility does not prevent every write conflict.",
      sourceRefs: [sourceRef],
    },
  ],
  relations: [
    {
      relationId: "relation.visibility.depends-version",
      type: "DEPENDS_ON",
      sourceRef: "element.visibility",
      targetRef: "element.version",
      origin: "SOURCE_EXPLICIT",
      riskLevel: "LOW",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
  ],
  sourceRefs: [sourceRef],
  gaps: [],
  qualityAssessment: {
    schemaVersion: "2.0.0",
    artifactId: "assessment.module.mvcc",
    revisionId: "rev.assessment.module.mvcc.1",
    publicationState: "PUBLISHED",
    subjectRef: "module.mvcc",
    hierarchyCorrectness: { status: "PASS", findings: [] },
    granularityFitness: { status: "PASS", findings: [] },
    cognitiveClosure: { status: "PASS", findings: [] },
    spineCoherence: { status: "PASS", findings: [] },
    importanceAccuracy: { status: "PASS", findings: [] },
    sourceFaithfulness: { status: "PASS", findings: [] },
    compressionEfficiency: { status: "PASS", findings: [] },
    hardFailures: [],
  },
};

describe("projectModuleNarrative", () => {
  it("projects the published canonical narrative without reordering or copying", () => {
    const projection = projectModuleNarrative(schemaValidModule);

    expect(projection).toEqual({
      moduleRef: "module.mvcc",
      title: "MVCC",
      coreQuestions: ["How does a read choose a visible version?"],
      coreConclusion: "MVCC coordinates readers and writers.",
      spineSteps: schemaValidSteps,
    });
    expect(projection.coreQuestions).toBe(schemaValidModule.coreQuestions);
    expect(projection.spineSteps).toHaveLength(4);
    projection.spineSteps.forEach((step, index) =>
      expect(step).toBe(schemaValidSteps[index]),
    );
  });

  it("preserves all nine canonical spine steps by identity and order", () => {
    const nineSteps = [
      ...schemaValidSteps,
      ...Array.from({ length: 5 }, (_, index) => ({
        stepId: `spine-step.mvcc.${index + 5}`,
        order: index + 5,
        statement: `Canonical step ${index + 5}.`,
        sourceRefs: [sourceRef],
      })),
    ];
    const projection = projectModuleNarrative({
      ...schemaValidModule,
      primaryCognitiveSpine: {
        ...schemaValidModule.primaryCognitiveSpine!,
        steps: nineSteps,
      },
    });

    expect(projection.spineSteps).toHaveLength(9);
    projection.spineSteps.forEach((step, index) =>
      expect(step).toBe(nineSteps[index]),
    );
  });

  it.each(["DRAFT", "CONFIRMED"] as const)(
    "rejects a %s module",
    (publicationState) => {
      expect(() =>
        projectModuleNarrative({ ...schemaValidModule, publicationState }),
      ).toThrow("MODULE_READING_REQUIRES_PUBLISHED_CANONICAL_MODULE");
    },
  );
});
