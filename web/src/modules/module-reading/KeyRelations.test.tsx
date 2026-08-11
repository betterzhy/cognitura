import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type {
  CognitiveModule,
  CognitiveRelation,
  RendererInput,
  RendererRelation,
} from "./model";
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
  primaryCognitiveSpine: null,
  facets: [],
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
  keyTakeaways: [],
  criticalBoundaries: [],
  relations: canonicalRelations,
  sourceRefs: [sourceRef],
  gaps: [],
  qualityAssessment: null,
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
  relations: canonicalModule.relations.map(projectRelation),
  sourceRefs: [sourceRef],
  incompleteState: { status: "COMPLETE", gapRefs: [] },
  interactionHints: ["SHOW_SOURCE"],
};

describe("KeyRelations", () => {
  it("projects identity, type, direction, and canonical endpoint labels", () => {
    const input = rendererInputWithTwoRelations;
    render(<KeyRelations input={input} />);
    const relationList = screen.getByRole("list", { name: "Key relations" });
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
        item.type,
        nodeById.get(item.targetNodeRef)?.label,
      ]),
    );
    relationItems.forEach((item, index) => {
      expect(item).not.toHaveTextContent(input.relations[index].sourceNodeRef);
      expect(item).not.toHaveTextContent(input.relations[index].targetNodeRef);
    });
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
      relations: Array.from({ length: 4 }, (_, index) => ({
        ...rendererInputWithTwoRelations.relations[index % 2],
        relationId: `renderer-relation.budget-${index + 1}`,
      })),
    };

    expect(() => render(<KeyRelations input={input} />)).toThrow(
      "MODULE_DEFAULT_READING_RELATION_BUDGET_EXCEEDED",
    );
  });
});
