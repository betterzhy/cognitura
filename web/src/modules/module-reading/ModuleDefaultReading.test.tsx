import { cleanup, render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import cognitiveModuleFixture from "../../../../tests/contracts/schema/fixtures/valid/cognitive-module.json";
import type {
  CognitiveModule,
  RendererInput,
  RendererRelation,
} from "./model";
import { ModuleDefaultReading } from "./ModuleDefaultReading";
import moduleDefaultReadingCss from "./module-default-reading.css?raw";

const nodeFsModule = "node:fs";
const { readFileSync } = await import(nodeFsModule);
const moduleDefaultReadingStyles =
  moduleDefaultReadingCss ||
  readFileSync("src/modules/module-reading/module-default-reading.css", "utf8");

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

const forbiddenDashboardClassFragment =
  /(?:dashboard|card-wall|metric|coverage|progress|glass|gradient)/i;

function expectNoDashboardPresentationHooks(root: HTMLElement) {
  const elements = [
    root,
    ...root.querySelectorAll<HTMLElement>("[class]"),
  ];
  const forbiddenClasses = elements.flatMap((element) =>
    Array.from(element.classList).filter((className) =>
      forbiddenDashboardClassFragment.test(className),
    ),
  );
  const forbiddenDataAttributes = [
    root,
    ...root.querySelectorAll<HTMLElement>("*"),
  ].flatMap((element) =>
    ["data-dashboard", "data-card-wall"].filter((attribute) =>
      element.hasAttribute(attribute),
    ),
  );
  expect(forbiddenClasses).toEqual([]);
  expect(forbiddenDataAttributes).toEqual([]);
}

function assertExactComposition(main: HTMLElement) {
  const questions = within(main).getByRole("list", { name: "核心问题" });
  const conclusion = within(main).getByRole("region", {
    name: "核心结论",
  });
  const spine = within(main).getByRole("list", {
    name: "认知主线",
  });
  const stageChain = within(main).getByRole("list", { name: "机制路径" });
  const boundaries = within(main).getByRole("list", {
    name: "边界与例外",
  });
  const elements = within(main).getByRole("list", {
    name: "关键知识",
  });
  const relations = within(main).getByRole("list", { name: "局部关系" });
  const sourceSection = within(main).getByRole("region", { name: "来源锚点" });
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
    rendererInput.nodes.map((node, index) => [
      node.nodeId,
      `${index + 1}${node.label}${node.summary}`,
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
      "依赖于",
      "",
      nodeById.get(relation.targetNodeRef)?.label,
    ]),
  );
  expect(sourceEntry).toHaveAttribute(
    "data-source-refs",
    JSON.stringify(rendererInput.sourceRefs),
  );
  expect(sourceSection).toHaveAttribute("data-reading-section", "source-entry");
  expect(sourceEntry).not.toHaveAttribute("data-reading-section");

  const sectionOrder = Array.from(
    main.querySelectorAll("[data-reading-section]"),
    (section) => section.getAttribute("data-reading-section"),
  );
  expect(sectionOrder).toEqual(expectedSectionOrder);
  expect(new Set(sectionOrder).size).toBe(sectionOrder.length);
  expect(main.textContent).not.toContain("evidence.mvcc");
  expect(main.textContent).not.toContain("DEPENDS_ON");
}

function renderedMainClone() {
  const { container, unmount } = render(
    <ModuleDefaultReading module={module} rendererInput={rendererInput} />,
  );
  const clone = container.querySelector("main")?.cloneNode(true) as HTMLElement;
  unmount();
  return clone;
}

function expectLocalLabelBinding(element: HTMLElement) {
  const headingId = element.getAttribute("aria-labelledby");
  expect(headingId).toBeTruthy();
  const heading = element.querySelector<HTMLElement>(`[id="${headingId}"]`);
  expect(heading).not.toBeNull();
  expect(heading).toBeVisible();
  return headingId;
}

function computedReadingMaxInlineSize(source: string) {
  const style = document.createElement("style");
  style.textContent = source;
  document.head.append(style);
  const { container, unmount } = render(
    <ModuleDefaultReading module={module} rendererInput={rendererInput} />,
  );
  const reading = container.querySelector("main") as HTMLElement;
  const maxInlineSize = getComputedStyle(reading).maxInlineSize;
  unmount();
  style.remove();
  return maxInlineSize;
}

function expectReadingInlineContained(source: string) {
  expect(computedReadingMaxInlineSize(source)).toBe("100%");
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
    const main = screen.getByRole("main", { name: "MVCC" });
    assertExactComposition(main);
    expect(main).toHaveClass(
      "module-default-reading",
      "cka-visual-root",
      "cka-reading-surface",
    );
    expect(main).toHaveAttribute("data-reading-flow", "continuous-document");
    expectLocalLabelBinding(main);
    expect(within(main).getByRole("heading", { level: 1 })).toHaveClass(
      "cka-type-object-title",
    );
    expect(
      main.querySelector('[data-primary-visual-projection="true"]'),
    ).toHaveClass(
      "module-default-reading__primary-projection",
      "cka-projection-surface",
    );
    expect(screen.getByText("认知模块", { exact: true })).toHaveClass(
      "module-default-reading__eyebrow",
    );
    expect(main.querySelectorAll("aside, [role='complementary']")).toHaveLength(0);
    expectNoDashboardPresentationHooks(main);
  });

  it("keeps the accessible module label local to each rendered instance", () => {
    const { container } = render(
      <>
        <ModuleDefaultReading module={module} rendererInput={rendererInput} />
        <ModuleDefaultReading module={module} rendererInput={rendererInput} />
      </>,
    );
    const mains = within(container).getAllByRole("main", { name: "MVCC" });
    const headingIds = mains.map(expectLocalLabelBinding);

    expect(mains).toHaveLength(2);
    expect(new Set(headingIds).size).toBe(headingIds.length);
  });

  it("consumes the production style authority without parallel theme values", () => {
    const requiredAuthority = [
      '../../styles/cognitura.css',
      "--reading-column-width",
      "--surface-reading",
      "--surface-projection",
      "--border-subtle",
      "--text-primary",
      "--text-secondary",
      "--color-primary",
      "--color-warning",
      "--color-info",
      "--radius-lg",
    ];

    requiredAuthority.forEach((token) =>
      expect(moduleDefaultReadingStyles).toContain(token),
    );
    expect(moduleDefaultReadingStyles).toMatch(/@media\s*\(max-width:/);
    expect(moduleDefaultReadingStyles).not.toMatch(/#[0-9a-f]{3,8}\b/i);
    expect(moduleDefaultReadingStyles).not.toMatch(/\b(?:rgb|hsl)a?\(/i);
    expect(moduleDefaultReadingStyles).not.toMatch(/gradient\s*\(/i);
    expect(moduleDefaultReadingStyles).toMatch(
      /\.module-default-reading__eyebrow\s*\{[^}]*color:\s*var\(--color-focus\)/s,
    );
    expect(moduleDefaultReadingStyles).not.toContain("cka-status-focus");
    expect(moduleDefaultReadingStyles).not.toContain("data-relation-strength");
    expect(moduleDefaultReadingStyles).not.toMatch(
      /\.key-relations[^{}]*\{[^}]*(?:--color-focus|--color-focus-soft)/s,
    );
    expect(moduleDefaultReadingStyles).toContain(
      "width: min(100%, var(--projection-width))",
    );
    expect(moduleDefaultReadingStyles).toContain(
      ".module-default-reading > :not(.module-default-reading__primary-projection)",
    );
    expect(moduleDefaultReadingStyles).toContain(
      "width: min(100%, var(--reading-column-width))",
    );
    expect(moduleDefaultReadingStyles).not.toContain("100vw");
    expect(moduleDefaultReadingStyles).toContain("min-inline-size: 0");
    expectReadingInlineContained(moduleDefaultReadingStyles);
    expect(() =>
      expectReadingInlineContained(
        `${moduleDefaultReadingStyles}\n.module-default-reading { max-inline-size: none; }`,
      ),
    ).toThrow();
    expect(moduleDefaultReadingStyles).toMatch(/max-width:\s*64rem/);
    expect(moduleDefaultReadingStyles).toMatch(/max-width:\s*48rem/);
    expect(moduleDefaultReadingStyles).toContain("overflow-x: hidden");
    expect(moduleDefaultReadingStyles).not.toMatch(
      /\.key-relations[^{}]*(?::first-child|:nth-child)/,
    );
    expect(moduleDefaultReadingStyles).not.toContain("ui-serif");
    expect(moduleDefaultReadingStyles).not.toContain("Georgia");
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

  it("keeps every forbidden dashboard class substring mutation RED", () => {
    [
      "module-dashboard-summary",
      "reading-card-wall-grid",
      "module-metric-row",
      "source-coverage-ring",
      "stage-progress-indicator",
      "reading-glass-surface",
      "visual-gradient-banner",
    ].forEach((forbiddenClass) => {
      const mutated = renderedMainClone();
      mutated.classList.add(forbiddenClass);
      expect(() => expectNoDashboardPresentationHooks(mutated)).toThrow();
    });

    const rootAttributeMutation = renderedMainClone();
    rootAttributeMutation.setAttribute("data-dashboard", "");
    expect(() => expectNoDashboardPresentationHooks(rootAttributeMutation)).toThrow();

    const descendantAttributeMutation = renderedMainClone();
    descendantAttributeMutation
      .querySelector('[data-reading-section="stage-chain"]')
      ?.setAttribute("data-card-wall", "arbitrary-value");
    expect(() =>
      expectNoDashboardPresentationHooks(descendantAttributeMutation),
    ).toThrow();
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

  it("fails closed when Renderer relation semantics drift from the formal module", () => {
    const renderWithRelationMutation = (
      mutation: Partial<RendererRelation>,
    ) =>
      render(
        <ModuleDefaultReading
          module={module}
          rendererInput={{
            ...rendererInput,
            relations: [{ ...rendererInput.relations[0], ...mutation }],
          }}
        />,
      );

    expect(() =>
      renderWithRelationMutation({
        artifactRelationRef: "relation.not-in-module",
      }),
    ).toThrow("RENDERER_RELATION_OUT_OF_SCOPE");
    expect(() => renderWithRelationMutation({ type: "IMPACTS" })).toThrow(
      "RENDERER_RELATION_TYPE_CHANGED",
    );
    expect(() =>
      renderWithRelationMutation({
        sourceNodeRef: "renderer-node.version",
      }),
    ).toThrow("RENDERER_RELATION_ENDPOINT_CHANGED");
    expect(() =>
      renderWithRelationMutation({
        targetNodeRef: "renderer-node.visibility",
      }),
    ).toThrow("RENDERER_RELATION_ENDPOINT_CHANGED");
    expect(() => renderWithRelationMutation({ sourceRefs: [] })).toThrow(
      "RENDERER_RELATION_SOURCE_CHANGED",
    );
  });

  it("rejects content paths that formal JSON Pointer resolution cannot index", () => {
    const nodes = rendererInput.nodes.map((node, index) =>
      index === 0
        ? { ...node, contentPath: "/knowledgeElements/00/title" }
        : node,
    );

    expect(() =>
      render(
        <ModuleDefaultReading
          module={module}
          rendererInput={{ ...rendererInput, nodes }}
        />,
      ),
    ).toThrow("RENDERER_RELATION_ENDPOINT_CHANGED");
  });
});
