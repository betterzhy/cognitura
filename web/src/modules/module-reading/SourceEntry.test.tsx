import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { SourceEntry } from "./SourceEntry";

describe("SourceEntry", () => {
  it("projects a focusable, closed source entry without exposing source IDs", () => {
    const sourceRefs = ["evidence.mvcc"];
    const { container } = render(<SourceEntry sourceRefs={sourceRefs} />);
    const button = screen.getByRole("button", {
      name: "查看 1 条来源证据",
    });

    expect(button).toBeVisible();
    expect(button).toHaveAttribute(
      "data-source-refs",
      JSON.stringify(sourceRefs),
    );
    expect(button).toHaveAttribute("data-reading-section", "source-entry");
    expect(
      container.querySelectorAll('[data-reading-section="source-entry"]'),
    ).toHaveLength(1);
    expect(screen.queryByText(sourceRefs[0])).toBeNull();
    expect(screen.queryByRole("complementary")).toBeNull();

    button.focus();
    expect(button).toHaveFocus();
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
