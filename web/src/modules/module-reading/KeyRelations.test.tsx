import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { RendererInput, RendererRelation } from "./model";
import { KeyRelations } from "./KeyRelations";

const relation = (
  relationId: string,
  type: RendererRelation["type"],
  sourceNodeRef: string,
  targetNodeRef: string,
): RendererRelation => ({
  relationId,
  type,
  sourceNodeRef,
  targetNodeRef,
  artifactRelationRef: `artifact-${relationId}`,
  sourceRefs: ["evidence.mvcc"],
});

const rendererInputWithTwoRelations: RendererInput = {
  schemaVersion: "2.0.0",
  moduleRef: "module.mvcc",
  rendererType: "STAGE_CHAIN",
  title: "MVCC visibility stages",
  summary: "Canonical stages for choosing a visible record version.",
  nodes: [
    {
      nodeId: "renderer-node.version",
      artifactRef: "module.mvcc",
      contentPath: "/knowledgeElements/1",
      label: "Record version",
      summary: "A historical record state.",
      groupRef: null,
      sourceRefs: ["evidence.mvcc"],
    },
    {
      nodeId: "renderer-node.visibility",
      artifactRef: "module.mvcc",
      contentPath: "/knowledgeElements/0",
      label: "Visibility judgment",
      summary: "Select the newest visible version.",
      groupRef: null,
      sourceRefs: ["evidence.mvcc"],
    },
  ],
  groups: [],
  relations: [
    relation(
      "renderer-relation.visibility-depends-version",
      "DEPENDS_ON",
      "renderer-node.visibility",
      "renderer-node.version",
    ),
    relation(
      "renderer-relation.version-impacts-visibility",
      "IMPACTS",
      "renderer-node.version",
      "renderer-node.visibility",
    ),
  ],
  sourceRefs: ["evidence.mvcc"],
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
        relation(
          "renderer-relation.missing-target",
          "DEPENDS_ON",
          "renderer-node.visibility",
          "renderer-node.missing",
        ),
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
      relations: Array.from({ length: 4 }, (_, index) =>
        relation(
          `renderer-relation.budget-${index + 1}`,
          "EXPLAINS",
          "renderer-node.visibility",
          "renderer-node.version",
        ),
      ),
    };

    expect(() => render(<KeyRelations input={input} />)).toThrow(
      "MODULE_DEFAULT_READING_RELATION_BUDGET_EXCEEDED",
    );
  });
});
