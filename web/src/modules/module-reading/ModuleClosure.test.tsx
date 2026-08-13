import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { ModuleClosureProjection } from "./model";
import { ModuleClosure } from "./ModuleClosure";
import { projectModuleClosure } from "./projectModuleNarrative";

const moduleClosureSource: ModuleClosureProjection = {
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
      sourceRefs: ["evidence.mvcc"],
      relations: ["relation.visibility.depends-version"],
    },
    {
      schemaVersion: "2.0.0",
      artifactId: "element.version",
      revisionId: "rev.element.version.1",
      publicationState: "PUBLISHED",
      moduleRef: "module.mvcc",
      elementType: "CONCEPT",
      title: "Record version",
      content: "A record version preserves one historical state.",
      sourceRefs: ["evidence.mvcc"],
      relations: ["relation.visibility.depends-version"],
    },
  ],
  criticalBoundaries: [
    {
      boundaryId: "boundary.mvcc.1",
      statement: "Visibility does not prevent every write conflict.",
      sourceRefs: ["evidence.mvcc"],
    },
  ],
};

const projection = projectModuleClosure(moduleClosureSource);

describe("ModuleClosure", () => {
  it("renders boundaries before elements without inferred semantics", () => {
    const { container } = render(
      <ModuleClosure
        boundaries={projection.criticalBoundaries}
        elements={projection.knowledgeElements}
      />,
    );

    expect(projection.knowledgeElements).toBe(
      moduleClosureSource.knowledgeElements,
    );
    expect(projection.criticalBoundaries).toBe(
      moduleClosureSource.criticalBoundaries,
    );
    const elements = screen.getByRole("list", { name: "关键知识" });
    const boundaries = screen.getByRole("list", {
      name: "边界与例外",
    });

    expect(
      within(elements)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual(
      projection.knowledgeElements.map((item) => `${item.title}${item.content}`),
    );
    expect(
      within(elements)
        .getAllByRole("listitem")
        .map((item) => item.dataset.elementId),
    ).toEqual(projection.knowledgeElements.map((item) => item.artifactId));
    expect(
      within(boundaries)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual(projection.criticalBoundaries.map((item) => item.statement));
    expect(
      within(boundaries)
        .getAllByRole("listitem")
        .map((item) => item.dataset.boundaryId),
    ).toEqual(projection.criticalBoundaries.map((item) => item.boundaryId));
    expect(
      Array.from(
        container.querySelectorAll("[data-reading-section]"),
        (section) => section.getAttribute("data-reading-section"),
      ),
    ).toEqual(["boundaries", "elements"]);
    expect(
      screen.queryByRole("heading", { name: /Conditions|Results/ }),
    ).toBeNull();
    expect(
      container.querySelector('[data-reading-section="boundaries"]'),
    ).toHaveClass("module-closure__boundaries", "cka-semantic-boundary");
    expect(
      container.querySelector('[data-reading-section="elements"]'),
    ).toHaveClass("module-closure__elements");
    expect(container.querySelectorAll(".cka-projection-surface")).toHaveLength(
      0,
    );
    screen.getAllByRole("heading", { level: 2 }).forEach((heading) =>
      expect(heading).toHaveClass("cka-type-major-section"),
    );
  });
});
