import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { SourceEntry } from "./SourceEntry";

describe("SourceEntry", () => {
  it("projects a focusable, closed source entry without exposing source IDs", () => {
    const sourceRefs = ["evidence.mvcc"];
    const { container } = render(<SourceEntry sourceRefs={sourceRefs} />);
    const section = screen.getByRole("region", { name: "来源锚点" });
    const button = screen.getByRole("button", {
      name: "查看 1 条来源证据",
    });

    expect(button).toBeVisible();
    expect(button).toHaveAttribute(
      "data-source-refs",
      JSON.stringify(sourceRefs),
    );
    expect(section).toHaveAttribute("data-reading-section", "source-entry");
    const headingId = section.getAttribute("aria-labelledby");
    expect(headingId).toBeTruthy();
    expect(within(section).getByText("来源锚点", { exact: true })).toHaveAttribute(
      "id",
      headingId,
    );
    expect(section).toHaveClass("module-source-entry");
    expect(button).not.toHaveAttribute("data-reading-section");
    expect(button).toHaveClass("module-source-entry__action", "cka-focusable");
    expect(section).toHaveTextContent("来源锚点");
    expect(section).toHaveTextContent("关键结论可回到正式来源核验。");
    expect(within(section).getAllByRole("button")).toHaveLength(1);
    expect(
      container.querySelectorAll('[data-reading-section="source-entry"]'),
    ).toHaveLength(1);
    expect(screen.queryByText(sourceRefs[0])).toBeNull();
    expect(screen.queryByRole("complementary")).toBeNull();

    button.focus();
    expect(button).toHaveFocus();
  });

  it("keeps the source label binding local across multiple instances", () => {
    const { container } = render(
      <>
        <SourceEntry sourceRefs={["evidence.mvcc"]} />
        <SourceEntry sourceRefs={["evidence.mvcc"]} />
      </>,
    );
    const sections = Array.from(
      container.querySelectorAll<HTMLElement>('[data-reading-section="source-entry"]'),
    );
    const headingIds = sections.map((section) => {
      const headingId = section.getAttribute("aria-labelledby");
      expect(headingId).toBeTruthy();
      const heading = section.querySelector(".module-section-label");
      expect(heading).toHaveAttribute(
        "id",
        headingId,
      );
      expect(heading).toBeVisible();
      return headingId;
    });

    expect(sections).toHaveLength(2);
    expect(new Set(headingIds).size).toBe(headingIds.length);
  });

  it("preserves all source refs in input order as machine-only data", () => {
    const sourceRefs = ["evidence.mvcc", "evidence.read-view"];
    render(<SourceEntry sourceRefs={sourceRefs} />);
    const button = screen.getByRole("button", {
      name: "查看 2 条来源证据",
    });

    expect(button).toHaveAttribute(
      "data-source-refs",
      JSON.stringify(sourceRefs),
    );
    sourceRefs.forEach((sourceRef) =>
      expect(screen.queryByText(sourceRef)).toBeNull(),
    );
  });

  it("fails closed when no authoritative source ref is available", () => {
    expect(() => render(<SourceEntry sourceRefs={[]} />)).toThrow(
      "MODULE_DEFAULT_READING_SOURCE_REQUIRED",
    );
  });
});
