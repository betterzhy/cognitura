import { cleanup, render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import cognitiveModuleFixture from "../../../../tests/contracts/schema/fixtures/valid/cognitive-module.json";
import type { CognitiveModule, RendererInput } from "./model";
import { ModuleDefaultReading } from "./ModuleDefaultReading";

const module = cognitiveModuleFixture as unknown as CognitiveModule;

afterEach(cleanup);

const rendererInput: RendererInput = {
  schemaVersion: "2.0.0",
  moduleRef: "module.mvcc",
  rendererType: "STAGE_CHAIN",
  title: "MVCC visibility stages",
  summary: "Canonical stages for choosing a visible record version.",
  nodes: [
    {
      nodeId: "renderer-node.visibility",
      artifactRef: "module.mvcc",
      contentPath: "/knowledgeElements/0/title",
      label: "Visibility judgment",
      summary: "A read view selects the newest visible record version.",
      groupRef: null,
      sourceRefs: ["evidence.mvcc"],
    },
    {
      nodeId: "renderer-node.version",
      artifactRef: "module.mvcc",
      contentPath: "/knowledgeElements/1/title",
      label: "Record version",
      summary: "A record version preserves one historical state.",
      groupRef: null,
      sourceRefs: ["evidence.mvcc"],
    },
  ],
  groups: [],
  relations: [
    {
      relationId: "renderer-relation.visibility.depends-version",
      type: "DEPENDS_ON",
      sourceNodeRef: "renderer-node.visibility",
      targetNodeRef: "renderer-node.version",
      artifactRelationRef: "relation.visibility.depends-version",
      sourceRefs: ["evidence.mvcc"],
    },
  ],
  sourceRefs: ["evidence.mvcc"],
  incompleteState: { status: "COMPLETE", gapRefs: [] },
  interactionHints: ["SHOW_SOURCE"],
};

const expectedSectionOrder = [
  "core-questions",
  "core-conclusion",
  "primary-spine",
  "stage-chain",
  "boundaries",
  "elements",
  "relations",
  "source-entry",
] as const;

function assertExactComposition(main: HTMLElement) {
  const questions = within(main).getByRole("list", { name: "Core questions" });
  const conclusion = within(main).getByRole("region", {
    name: "Core conclusion",
  });
  const spine = within(main).getByRole("list", {
    name: "Primary cognitive spine",
  });
  const stageChain = within(main).getByRole("list", { name: "Stage chain" });
  const boundaries = within(main).getByRole("list", {
    name: "Critical boundaries",
  });
  const elements = within(main).getByRole("list", {
    name: "Knowledge elements",
  });
  const relations = within(main).getByRole("list", { name: "Key relations" });
  const sourceEntry = within(main).getByRole("button", {
    name: `查看 ${rendererInput.sourceRefs.length} 条来源证据`,
  });
  const nodeById = new Map(rendererInput.nodes.map((node) => [node.nodeId, node]));

  expect(main.querySelectorAll("[data-reading-section]")).toHaveLength(8);
  expect(main.querySelectorAll('[data-reading-section="source-entry"]')).toHaveLength(1);
  expect(main.querySelectorAll('[data-primary-visual-projection="true"]')).toHaveLength(1);
  expect(within(main).queryByRole("complementary")).toBeNull();
  expect(within(main).getAllByRole("button")).toHaveLength(1);
  expect(
    within(questions)
      .getAllByRole("listitem")
      .map((item) => item.textContent),
  ).toEqual(module.coreQuestions);
  expect(
    within(conclusion).getAllByText(module.thesis, { exact: true }),
  ).toHaveLength(1);
  expect(
    within(spine)
      .getAllByRole("listitem")
      .map((item) => [item.dataset.stepId, item.textContent]),
  ).toEqual(
    module.primaryCognitiveSpine?.steps.map((step) => [
      step.stepId,
      step.statement,
    ]),
  );
  expect(
    within(stageChain)
      .getAllByRole("listitem")
      .map((item) => [item.dataset.nodeId, item.textContent]),
  ).toEqual(
    rendererInput.nodes.map((node) => [
      node.nodeId,
      `${node.label}${node.summary}`,
    ]),
  );
  expect(
    within(boundaries)
      .getAllByRole("listitem")
      .map((item) => [item.dataset.boundaryId, item.textContent]),
  ).toEqual(
    module.criticalBoundaries.map((boundary) => [
      boundary.boundaryId,
      boundary.statement,
    ]),
  );
  expect(
    within(elements)
      .getAllByRole("listitem")
      .map((item) => [item.dataset.elementId, item.textContent]),
  ).toEqual(
    module.knowledgeElements.map((element) => [
      element.artifactId,
      `${element.title}${element.content}`,
    ]),
  );
  expect(
    within(relations)
      .getAllByRole("listitem")
      .map((item) => [
        item.dataset.relationId,
        item.dataset.relationType,
        item.dataset.sourceNodeRef,
        item.dataset.targetNodeRef,
        ...Array.from(
          item.querySelectorAll("[data-relation-part]"),
          (part) => part.textContent,
        ),
      ]),
  ).toEqual(
    rendererInput.relations.map((relation) => [
      relation.relationId,
      relation.type,
      relation.sourceNodeRef,
      relation.targetNodeRef,
      nodeById.get(relation.sourceNodeRef)?.label,
      relation.type,
      nodeById.get(relation.targetNodeRef)?.label,
    ]),
  );
  expect(sourceEntry).toHaveAttribute(
    "data-source-refs",
    JSON.stringify(rendererInput.sourceRefs),
  );

  const sectionOrder = Array.from(
    main.querySelectorAll("[data-reading-section]"),
    (section) => section.getAttribute("data-reading-section"),
  );
  expect(sectionOrder).toEqual(expectedSectionOrder);
  expect(new Set(sectionOrder).size).toBe(sectionOrder.length);
  expect(main.textContent).not.toContain("evidence.mvcc");
}

function renderedMainClone() {
  const { container, unmount } = render(
    <ModuleDefaultReading module={module} rendererInput={rendererInput} />,
  );
  const clone = container.querySelector("main")?.cloneNode(true) as HTMLElement;
  unmount();
  return clone;
}

describe("ModuleDefaultReading", () => {
  it("composes the exact canonical reading projection in document order", () => {
    expect(module.artifactId).toBe("module.mvcc");
    expect(module.publicationState).toBe("PUBLISHED");
    expect(module.primaryCognitiveSpine).not.toBeNull();
    expect(module.relations).toEqual([
      expect.objectContaining({
        relationId: "relation.visibility.depends-version",
        type: "DEPENDS_ON",
        sourceRef: "element.visibility",
        targetRef: "element.version",
      }),
    ]);
    expect(rendererInput.moduleRef).toBe(module.artifactId);
    expect(rendererInput.relations[0].artifactRelationRef).toBe(
      module.relations[0].relationId,
    );

    render(<ModuleDefaultReading module={module} rendererInput={rendererInput} />);

    expect(screen.getAllByRole("main")).toHaveLength(1);
    assertExactComposition(screen.getByRole("main", { name: "MVCC" }));
  });

  it("keeps deletion, duplication, and reordering mutations RED", () => {
    const deleted = renderedMainClone();
    deleted.querySelector('[data-reading-section="boundaries"]')?.remove();
    expect(() => assertExactComposition(deleted)).toThrow();

    const duplicated = renderedMainClone();
    const elements = duplicated.querySelector('[data-reading-section="elements"]');
    elements?.after(elements.cloneNode(true));
    expect(() => assertExactComposition(duplicated)).toThrow();

    const reordered = renderedMainClone();
    const stageChain = reordered.querySelector('[data-reading-section="stage-chain"]');
    const relations = reordered.querySelector('[data-reading-section="relations"]');
    relations?.after(stageChain as Node);
    expect(() => assertExactComposition(reordered)).toThrow();
  });

  it("keeps canonical relation identity, type, source, and target mutations RED", () => {
    const mutations: readonly [string, string][] = [
      ["relationId", "renderer-relation.changed"],
      ["relationType", "IMPACTS"],
      ["sourceNodeRef", "renderer-node.version"],
      ["targetNodeRef", "renderer-node.visibility"],
    ];

    mutations.forEach(([datasetKey, value]) => {
      const mutated = renderedMainClone();
      const relation = mutated.querySelector(
        '[data-reading-section="relations"] li',
      ) as HTMLElement;
      relation.dataset[datasetKey] = value;
      expect(() => assertExactComposition(mutated)).toThrow();
    });
  });
});
