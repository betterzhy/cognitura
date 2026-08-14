import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { ModuleNarrativeProjection } from "./model";
import { ModuleNarrative } from "./ModuleNarrative";

const projection: ModuleNarrativeProjection = {
  moduleRef: "module.mvcc",
  title: "MVCC",
  coreQuestions: [
    "How does a read choose a visible version?",
    "When can an old version be retired?",
  ],
  coreConclusion: "MVCC coordinates readers and writers.",
  spineSteps: [
    {
      stepId: "spine-step.mvcc.1",
      order: 1,
      statement: "Create a version.",
      sourceRefs: ["evidence.mvcc"],
    },
    {
      stepId: "spine-step.mvcc.2",
      order: 2,
      statement: "Select a visible version.",
      sourceRefs: ["evidence.mvcc"],
    },
  ],
};

function expectLocalSectionLabels(container: HTMLElement) {
  const sections = Array.from(
    container.querySelectorAll<HTMLElement>("[data-reading-section]"),
  );
  return sections.map((section) => {
    const headingId = section.getAttribute("aria-labelledby");
    expect(headingId).toBeTruthy();
    const heading = section.querySelector<HTMLElement>(`[id="${headingId}"]`);
    expect(heading).not.toBeNull();
    expect(heading).toBeVisible();
    return headingId;
  });
}

describe("ModuleNarrative", () => {
  it("renders questions, conclusion, and spine in canonical order", () => {
    const { container } = render(<ModuleNarrative projection={projection} />);
    const questions = screen.getByRole("list", { name: "核心问题" });
    const conclusion = screen.getByRole("region", {
      name: "核心结论",
    });
    const spine = screen.getByRole("list", {
      name: "认知主线",
    });

    expect(
      within(questions)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual(projection.coreQuestions);
    expect(
      within(conclusion).getAllByText(projection.coreConclusion, {
        exact: true,
      }),
    ).toHaveLength(1);
    expect(
      within(spine)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual(projection.spineSteps.map((step) => step.statement));
    expect(
      within(spine)
        .getAllByRole("listitem")
        .map((item) => item.dataset.stepId),
    ).toEqual(projection.spineSteps.map((step) => step.stepId));

    expect(
      Array.from(container.querySelectorAll("[data-reading-section]")).map(
        (section) => section.getAttribute("data-reading-section"),
      ),
    ).toEqual(["core-questions", "core-conclusion", "primary-spine"]);
    expectLocalSectionLabels(container);
    expect(
      container.querySelector('[data-reading-section="core-questions"]'),
    ).toHaveClass("module-narrative__questions");
    expect(conclusion).toHaveClass(
      "module-narrative__conclusion",
    );
    expect(conclusion).not.toHaveClass("cka-subtle-band");
    expect(
      container.querySelector('[data-reading-section="primary-spine"]'),
    ).toHaveClass("module-narrative__spine");
    screen.getAllByRole("heading", { level: 2 }).forEach((heading) =>
      expect(heading).toHaveClass("cka-type-major-section"),
    );
    expect(container.querySelectorAll(".cka-projection-surface")).toHaveLength(
      0,
    );
  });

  it("keeps every narrative section label local across multiple instances", () => {
    const { container } = render(
      <>
        <ModuleNarrative projection={projection} />
        <ModuleNarrative projection={projection} />
      </>,
    );
    const headingIds = expectLocalSectionLabels(container);

    expect(headingIds).toHaveLength(6);
    expect(new Set(headingIds).size).toBe(headingIds.length);
  });
});
