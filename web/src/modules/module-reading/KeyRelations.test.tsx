import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type {
  CognitiveModule,
  CognitiveRelation,
  RendererInput,
  RendererRelation,
} from "./model";
import { relationTypes } from "./model";
import { KeyRelations } from "./KeyRelations";

const sourceRef = "evidence.mvcc";
const moduleRef = "module.mvcc-relations";

const canonicalRelations: readonly CognitiveRelation[] = [
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
  {
    relationId: "relation.visibility.explains-version",
    type: "EXPLAINS",
    sourceRef: "element.visibility",
    targetRef: "element.version",
    origin: "SOURCE_EXPLICIT",
    riskLevel: "LOW",
    sourceRefs: [sourceRef],
    gapRefs: [],
  },
  {
    relationId: "relation.visibility.impacts-version",
    type: "IMPACTS",
    sourceRef: "element.visibility",
    targetRef: "element.version",
    origin: "SOURCE_EXPLICIT",
    riskLevel: "LOW",
    sourceRefs: [sourceRef],
    gapRefs: [],
  },
  {
    relationId: "relation.visibility.applies-to-version",
    type: "APPLIES_TO",
    sourceRef: "element.visibility",
    targetRef: "element.version",
    origin: "SOURCE_EXPLICIT",
    riskLevel: "LOW",
    sourceRefs: [sourceRef],
    gapRefs: [],
  },
];

const canonicalModule: CognitiveModule = {
  schemaVersion: "2.0.0",
  artifactId: moduleRef,
  revisionId: "rev.module.mvcc-relations.1",
  publicationState: "PUBLISHED",
  primaryParent: "theme.storage",
  title: "MVCC relation fixture",
  thesis: "Visibility judgment depends on and explains record versions.",
  role: "CORE",
  coreQuestions: ["How are visibility and record versions related?"],
  primaryCognitiveSpine: {
    schemaVersion: "2.0.0",
    artifactId: "spine.mvcc-relations",
    revisionId: "rev.spine.mvcc-relations.1",
    publicationState: "PUBLISHED",
    moduleRef,
    steps: [
      {
        stepId: "spine-step.mvcc-relations.1",
        order: 1,
        statement: "Create a record version.",
        sourceRefs: [sourceRef],
      },
      {
        stepId: "spine-step.mvcc-relations.2",
        order: 2,
        statement: "Capture a visibility boundary.",
        sourceRefs: [sourceRef],
      },
      {
        stepId: "spine-step.mvcc-relations.3",
        order: 3,
        statement: "Evaluate visible versions.",
        sourceRefs: [sourceRef],
      },
      {
        stepId: "spine-step.mvcc-relations.4",
        order: 4,
        statement: "Select the newest visible version.",
        sourceRefs: [sourceRef],
      },
    ],
  },
  facets: [
    {
      facetId: "facet.mvcc-relations.visibility",
      title: "Visibility",
      summary: "How visibility judgment relates to record versions.",
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
      moduleRef,
      elementType: "MECHANISM",
      title: "Visibility judgment",
      content: "Select the newest visible version.",
      sourceRefs: [sourceRef],
      relations: canonicalRelations.map((item) => item.relationId),
    },
    {
      schemaVersion: "2.0.0",
      artifactId: "element.version",
      revisionId: "rev.element.version.1",
      publicationState: "PUBLISHED",
      moduleRef,
      elementType: "CONCEPT",
      title: "Record version",
      content: "A historical record state.",
      sourceRefs: [sourceRef],
      relations: canonicalRelations.map((item) => item.relationId),
    },
  ],
  keyTakeaways: [
    {
      statementId: "takeaway.mvcc-relations.1",
      statement: "Visibility judgment selects among record versions.",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
    {
      statementId: "takeaway.mvcc-relations.2",
      statement: "Record versions preserve historical states.",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
    {
      statementId: "takeaway.mvcc-relations.3",
      statement: "The formal relations preserve direction and evidence.",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
  ],
  criticalBoundaries: [
    {
      boundaryId: "boundary.mvcc-relations.1",
      statement: "Visibility does not prevent every write conflict.",
      sourceRefs: [sourceRef],
    },
  ],
  relations: canonicalRelations,
  sourceRefs: [sourceRef],
  gaps: [],
  qualityAssessment: {
    schemaVersion: "2.0.0",
    artifactId: "assessment.module.mvcc-relations",
    revisionId: "rev.assessment.module.mvcc-relations.1",
    publicationState: "PUBLISHED",
    subjectRef: moduleRef,
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

const nodeIdByArtifactRef = new Map([
  ["element.visibility", "renderer-node.visibility"],
  ["element.version", "renderer-node.version"],
]);

const projectRelation = (
  relation: CognitiveRelation,
  index: number,
): RendererRelation => ({
  relationId: `renderer-relation.${index + 1}`,
  type: relation.type,
  sourceNodeRef: nodeIdByArtifactRef.get(relation.sourceRef)!,
  targetNodeRef: nodeIdByArtifactRef.get(relation.targetRef)!,
  artifactRelationRef: relation.relationId,
  sourceRefs: relation.sourceRefs,
});

const rendererInputWithTwoRelations: RendererInput = {
  schemaVersion: "2.0.0",
  moduleRef,
  rendererType: "STAGE_CHAIN",
  title: "MVCC visibility stages",
  summary: "Canonical stages for choosing a visible record version.",
  nodes: [
    {
      nodeId: "renderer-node.visibility",
      artifactRef: moduleRef,
      contentPath: "/knowledgeElements/0/title",
      label: "Visibility judgment",
      summary: "Select the newest visible version.",
      groupRef: null,
      sourceRefs: [sourceRef],
    },
    {
      nodeId: "renderer-node.version",
      artifactRef: moduleRef,
      contentPath: "/knowledgeElements/1/title",
      label: "Record version",
      summary: "A historical record state.",
      groupRef: null,
      sourceRefs: [sourceRef],
    },
  ],
  groups: [],
  relations: canonicalModule.relations.slice(0, 2).map(projectRelation),
  sourceRefs: [sourceRef],
  incompleteState: { status: "COMPLETE", gapRefs: [] },
  interactionHints: ["SHOW_SOURCE"],
};

const expectedRelationVerbs = {
  DEPENDS_ON: "依赖于",
  EXPLAINS: "解释",
  CONTRASTS_WITH: "对照于",
  APPLIES_TO: "适用于",
  IMPACTS: "影响",
} as const;

function relationVisualSemantics(container: HTMLElement) {
  return Array.from(
    container.querySelectorAll<HTMLElement>("[data-relation-id]"),
    (item) => ({
      className: item.className,
      relationId: item.dataset.relationId,
      relationStrength: item.dataset.relationStrength,
      visibleStatement: item.textContent,
    }),
  ).sort((left, right) =>
    (left.relationId ?? "").localeCompare(right.relationId ?? ""),
  );
}

describe("KeyRelations", () => {
  it("projects identity, type, direction, and canonical endpoint labels", () => {
    const input = rendererInputWithTwoRelations;
    render(<KeyRelations input={input} />);
    const relationList = screen.getByRole("list", { name: "局部关系" });
    expect(relationList.closest("section")).toHaveAttribute(
      "aria-labelledby",
      "key-relations-heading",
    );
    expect(screen.getByRole("heading", { level: 2 })).toHaveAttribute(
      "id",
      "key-relations-heading",
    );
    const relationItems = within(relationList).getAllByRole("listitem");
    const nodeById = new Map(input.nodes.map((node) => [node.nodeId, node]));

    expect(input.moduleRef).toBe(canonicalModule.artifactId);
    input.relations.forEach((item) => {
      const canonical = canonicalModule.relations.find(
        (relation) => relation.relationId === item.artifactRelationRef,
      );
      expect(canonical).toBeDefined();
      expect(item.type).toBe(canonical?.type);
      expect(item.sourceNodeRef).toBe(
        nodeIdByArtifactRef.get(canonical!.sourceRef),
      );
      expect(item.targetNodeRef).toBe(
        nodeIdByArtifactRef.get(canonical!.targetRef),
      );
      expect(item.sourceRefs).toBe(canonical?.sourceRefs);
    });

    expect(relationItems).toHaveLength(input.relations.length);
    expect(
      relationItems.map((item) => [
        item.dataset.relationId,
        item.dataset.relationType,
        item.dataset.sourceNodeRef,
        item.dataset.targetNodeRef,
      ]),
    ).toEqual(
      input.relations.map((item) => [
        item.relationId,
        item.type,
        item.sourceNodeRef,
        item.targetNodeRef,
      ]),
    );
    expect(
      relationItems.map((item) =>
        Array.from(
          item.querySelectorAll("[data-relation-part]"),
          (part) => part.textContent,
        ),
      ),
    ).toEqual(
      input.relations.map((item) => [
        nodeById.get(item.sourceNodeRef)?.label,
        expectedRelationVerbs[item.type],
        "",
        nodeById.get(item.targetNodeRef)?.label,
      ]),
    );
    relationItems.forEach((item, index) => {
      expect(item).not.toHaveTextContent(input.relations[index].sourceNodeRef);
      expect(item).not.toHaveTextContent(input.relations[index].targetNodeRef);
      expect(item).toHaveClass("cka-relation-statement");
      expect(
        item.querySelector('[data-relation-part="source"]'),
      ).toHaveClass("cka-relation-endpoint");
      expect(item.querySelector('[data-relation-part="type"]')).toHaveClass(
        "cka-relation-verb",
      );
      expect(
        item.querySelector('[data-relation-part="direction"]'),
      ).toHaveClass("cka-relation-direction");
      expect(
        item.querySelector('[data-relation-part="target"]'),
      ).toHaveClass("cka-relation-endpoint");
      expect(item).not.toHaveAttribute("data-relation-strength");
      expect(item).not.toHaveClass("cka-status-focus");
      expect(item.textContent).not.toContain(input.relations[index].type);
      expect(item.textContent).not.toMatch(/\b[A-Z]+_[A-Z_]+\b/);
    });
    expect(relationItems).toHaveLength(2);
  });

  it("maps every formal relation type to an exhaustive natural-language verb", () => {
    expect(Object.keys(expectedRelationVerbs)).toEqual(relationTypes);

    relationTypes.forEach((type) => {
      const input: RendererInput = {
        ...rendererInputWithTwoRelations,
        relations: [
          {
            ...rendererInputWithTwoRelations.relations[0],
            relationId: `renderer-relation.${type.toLowerCase()}`,
            type,
          },
        ],
      };
      const { container, unmount } = render(<KeyRelations input={input} />);
      const typeLabel = within(container).getByText(expectedRelationVerbs[type], {
        exact: true,
      });

      expect(typeLabel).toHaveAttribute("data-relation-part", "type");
      expect(typeLabel).not.toHaveTextContent(type);
      expect(typeLabel.textContent).not.toMatch(/_/);
      unmount();
    });
  });

  it("keeps every relation neutral and stable when the input order changes", () => {
    const { container, rerender } = render(
      <KeyRelations input={rendererInputWithTwoRelations} />,
    );
    const originalSemantics = relationVisualSemantics(container);

    expect(
      container.querySelectorAll(
        ".cka-status-focus, [data-relation-strength='focused'], [data-relation-strength='weak']",
      ),
    ).toHaveLength(0);

    rerender(
      <KeyRelations
        input={{
          ...rendererInputWithTwoRelations,
          relations: [...rendererInputWithTwoRelations.relations].reverse(),
        }}
      />,
    );

    expect(relationVisualSemantics(container)).toEqual(originalSemantics);
  });

  it("fails closed when a relation endpoint is missing", () => {
    const input: RendererInput = {
      ...rendererInputWithTwoRelations,
      relations: [
        {
          ...rendererInputWithTwoRelations.relations[0],
          targetNodeRef: "renderer-node.missing",
        },
      ],
    };

    expect(() => render(<KeyRelations input={input} />)).toThrow(
      "RENDERER_RELATION_ENDPOINT_MISSING",
    );
  });

  it("fails closed for an unknown relation type", () => {
    const input = {
      ...rendererInputWithTwoRelations,
      relations: [
        {
          ...rendererInputWithTwoRelations.relations[0],
          type: "UNKNOWN_RELATION_TYPE",
        },
      ],
    } as unknown as RendererInput;

    expect(() => render(<KeyRelations input={input} />)).toThrow(
      "RENDERER_RELATION_TYPE_UNSUPPORTED",
    );
  });

  it("requires at least one authoritative RendererInput relation", () => {
    const input: RendererInput = {
      ...rendererInputWithTwoRelations,
      relations: [],
    };

    expect(() => render(<KeyRelations input={input} />)).toThrow(
      "MODULE_DEFAULT_READING_RELATION_REQUIRED",
    );
  });

  it("rejects more than three authoritative RendererInput relations", () => {
    const input: RendererInput = {
      ...rendererInputWithTwoRelations,
      relations: canonicalModule.relations.map(projectRelation),
    };

    expect(() => render(<KeyRelations input={input} />)).toThrow(
      "MODULE_DEFAULT_READING_RELATION_BUDGET_EXCEEDED",
    );
  });
});
