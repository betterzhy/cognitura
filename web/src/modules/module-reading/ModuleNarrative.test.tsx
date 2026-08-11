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

describe("ModuleNarrative", () => {
  it("renders questions, conclusion, and spine in canonical order", () => {
    const { container } = render(<ModuleNarrative projection={projection} />);
    const questions = screen.getByRole("list", { name: "Core questions" });
    const conclusion = screen.getByRole("region", {
      name: "Core conclusion",
    });
    const spine = screen.getByRole("list", {
      name: "Primary cognitive spine",
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
  });
});
