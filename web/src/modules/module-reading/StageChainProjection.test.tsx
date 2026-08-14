import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { RendererInput } from "./model";
import { StageChainProjection } from "./StageChainProjection";

const rendererInput: RendererInput = {
  schemaVersion: "2.0.0",
  moduleRef: "module.mvcc",
  rendererType: "STAGE_CHAIN",
  title: "MVCC visibility stages",
  summary: "Canonical stages for choosing a visible record version.",
  nodes: [
    {
      nodeId: "renderer-node.mvcc.1",
      artifactRef: "module.mvcc",
      contentPath: "/primaryCognitiveSpine/steps/0",
      label: "Create a version",
      summary: "Preserve a historical record state.",
      groupRef: null,
      sourceRefs: ["evidence.mvcc"],
    },
    {
      nodeId: "renderer-node.mvcc.2",
      artifactRef: "module.mvcc",
      contentPath: "/primaryCognitiveSpine/steps/1",
      label: "Select visibility",
      summary: "Choose the newest visible version.",
      groupRef: null,
      sourceRefs: ["evidence.mvcc"],
    },
  ],
  groups: [],
  relations: [],
  sourceRefs: ["evidence.mvcc"],
  incompleteState: { status: "COMPLETE", gapRefs: [] },
  interactionHints: ["SHOW_SOURCE"],
};

describe("StageChainProjection", () => {
  it("projects only the canonical StageChain nodes in input order", () => {
    const { container } = render(
      <StageChainProjection moduleRef="module.mvcc" input={rendererInput} />,
    );
    const stageChain = screen.getByRole("list", { name: "机制路径" });

    expect(
      within(stageChain)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual(
      rendererInput.nodes.map(
        (node, index) => `${index + 1}${node.label}${node.summary}`,
      ),
    );
    expect(
      within(stageChain)
        .getAllByRole("listitem")
        .map((item) => item.dataset.nodeId),
    ).toEqual(rendererInput.nodes.map((node) => node.nodeId));
    expect(
      Array.from(container.querySelectorAll("[data-reading-section]"), (node) =>
        node.getAttribute("data-reading-section"),
      ),
    ).toEqual(["stage-chain"]);
    expect(container.firstElementChild).toHaveClass("stage-chain-projection");
    expect(container.firstElementChild).toHaveAttribute(
      "aria-labelledby",
      "stage-chain-projection-heading",
    );
    expect(screen.getByRole("heading", { level: 2 })).toHaveAttribute(
      "id",
      "stage-chain-projection-heading",
    );
    expect(container.firstElementChild).not.toHaveClass("cka-projection-surface");
    expect(
      screen.getByRole("heading", { name: rendererInput.title, level: 2 }),
    ).toHaveClass("cka-type-major-section");
    expect(screen.getByText(rendererInput.summary)).toHaveClass(
      "stage-chain-projection__summary",
    );
    expect(
      within(stageChain)
        .getAllByRole("listitem")
        .map((item) =>
          item.querySelector(".stage-chain-projection__number")?.textContent,
        ),
    ).toEqual(["1", "2"]);
  });

  it("fails closed when the module reference does not match", () => {
    expect(() =>
      render(
        <StageChainProjection moduleRef="module.other" input={rendererInput} />,
      ),
    ).toThrow("RENDERER_MODULE_REF_MISMATCH");
  });

  it("fails closed for every non-StageChain renderer type", () => {
    const forbiddenTypes: readonly RendererInput["rendererType"][] = [
      "HIERARCHY",
      "MATRIX",
      "DECISION_PATH",
      "STATE_TRANSITION",
      "COMPARISON",
      "CAUSAL_CHAIN",
      "LAYERED_STRUCTURE",
      "STRUCTURED_PANEL",
    ];

    forbiddenTypes.forEach((rendererType) => {
      expect(() =>
        render(
          <StageChainProjection
            moduleRef="module.mvcc"
            input={{ ...rendererInput, rendererType }}
          />,
        ),
      ).toThrow("RENDERER_TYPE_MISMATCH");
    });
  });
});
