import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

describe("web test environment", () => {
  it("exposes accessible DOM assertions", () => {
    render(<main aria-label="Cognitura test probe" />);

    expect(
      screen.getByRole("main", { name: "Cognitura test probe" }),
    ).toBeInTheDocument();
  });
});
