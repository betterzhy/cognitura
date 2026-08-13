import { describe, expect, it } from "vitest";

import cognitiveVisualCss from "./cognitive-visual.css?raw";
import cognituraCss from "./cognitura.css?raw";
import surfacesCss from "./surfaces.css?raw";
import tokensCss from "./tokens.css?raw";
import typographyCss from "./typography.css?raw";

const styles = {
  "tokens.css": tokensCss,
  "typography.css": typographyCss,
  "surfaces.css": surfacesCss,
  "cognitive-visual.css": cognitiveVisualCss,
  "cognitura.css": cognituraCss,
} as const;

const expectedTokens: Record<string, string> = {
  "--color-canvas": "#f7f9fc",
  "--surface-reading": "#ffffff",
  "--surface-projection": "#fafbfd",
  "--surface-subtle": "#f5f7fa",
  "--border-subtle": "#e7eaf0",
  "--border-default": "#e2e6ec",
  "--border-strong": "#d4dae3",
  "--text-primary": "#172033",
  "--text-secondary": "#475467",
  "--text-muted": "#667085",
  "--text-subtle": "#98a2b3",
  "--color-primary": "#4f67e8",
  "--color-primary-hover": "#455bdd",
  "--color-primary-active": "#3d50c9",
  "--color-primary-soft": "#eef2ff",
  "--color-focus": "#7c6cf2",
  "--color-focus-soft": "#f3f0ff",
  "--color-success": "#278c68",
  "--color-success-soft": "#ecf8f3",
  "--color-warning": "#c98526",
  "--color-warning-soft": "#fff6e5",
  "--color-danger": "#d64f58",
  "--color-danger-soft": "#fff0f1",
  "--color-info": "#4385e0",
  "--color-info-soft": "#eef6ff",
  "--font-interface":
    'Inter, "PingFang SC", "SF Pro Text", "Noto Sans SC", "Microsoft YaHei", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  "--font-reading": "var(--font-interface)",
  "--font-weight-regular": "400",
  "--font-weight-medium": "500",
  "--font-weight-semibold": "600",
  "--font-weight-bold": "700",
  "--type-page-title-size": "32px",
  "--type-page-title-line-height": "40px",
  "--type-object-title-size": "28px",
  "--type-object-title-line-height": "36px",
  "--type-major-section-size": "22px",
  "--type-major-section-line-height": "30px",
  "--type-cognitive-section-size": "18px",
  "--type-cognitive-section-line-height": "26px",
  "--type-reading-size": "16px",
  "--type-reading-line-height": "27px",
  "--type-ui-size": "14px",
  "--type-ui-line-height": "21px",
  "--type-metadata-size": "13px",
  "--type-metadata-line-height": "18px",
  "--type-caption-size": "12px",
  "--type-caption-line-height": "18px",
  "--space-1": "4px",
  "--space-2": "8px",
  "--space-3": "12px",
  "--space-4": "16px",
  "--space-5": "20px",
  "--space-6": "24px",
  "--space-8": "32px",
  "--space-10": "40px",
  "--space-12": "48px",
  "--space-16": "64px",
  "--reading-column-width": "52rem",
  "--projection-width": "64rem",
  "--application-max-width": "90rem",
  "--radius-xs": "6px",
  "--radius-sm": "8px",
  "--radius-md": "10px",
  "--radius-lg": "12px",
  "--radius-xl": "16px",
  "--radius-pill": "999px",
  "--shadow-xs": "0 1px 2px rgb(16 24 40 / 4%)",
  "--shadow-sm": "0 2px 6px rgb(16 24 40 / 5%)",
  "--shadow-md": "0 6px 18px rgb(16 24 40 / 7%)",
  "--focus-ring-width": "2px",
  "--focus-ring-offset": "2px",
  "--focus-ring-color": "rgb(79 103 232 / 32%)",
  "--motion-fast": "140ms",
  "--motion-standard": "180ms",
  "--motion-easing": "ease-out",
};

const expectedNormalizedColorTokens = [
  "--color-canvas",
  "--surface-reading",
  "--surface-projection",
  "--surface-subtle",
  "--border-subtle",
  "--border-default",
  "--border-strong",
  "--text-primary",
  "--text-secondary",
  "--text-muted",
  "--text-subtle",
  "--color-primary",
  "--color-primary-hover",
  "--color-primary-active",
  "--color-primary-soft",
  "--color-focus",
  "--color-focus-soft",
  "--color-success",
  "--color-success-soft",
  "--color-warning",
  "--color-warning-soft",
  "--color-danger",
  "--color-danger-soft",
  "--color-info",
  "--color-info-soft",
];

const normalizeValue = (value: string) =>
  value.trim().replace(/\s+/g, " ").replace(/#[0-9A-F]{6}/g, (hex) => hex.toLowerCase());

const declarations = Object.entries(styles).flatMap(([file, css]) =>
  [...css.matchAll(/(^|[;{]\s*)(--[a-z0-9-]+)\s*:\s*([^;]+);/g)].map(
    ([, , name, value]) => ({ file, name, value: normalizeValue(value) }),
  ),
);

const blockFor = (css: string, selector: string) => {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = css.match(new RegExp(`${escaped}\\s*\\{([^}]*)\\}`));
  expect(match, `missing CSS rule for ${selector}`).not.toBeNull();
  return match?.[1] ?? "";
};

describe("Cognitura semantic style contract", () => {
  it("declares the complete exact token surface once and only in tokens.css", () => {
    expect(Object.keys(expectedTokens)).toHaveLength(75);
    expect(expectedNormalizedColorTokens).toHaveLength(25);
    expect(expectedNormalizedColorTokens.every((name) => name in expectedTokens)).toBe(true);
    expect(declarations).toHaveLength(Object.keys(expectedTokens).length);
    expect(new Set(declarations.map(({ name }) => name)).size).toBe(declarations.length);
    expect(new Set(declarations.map(({ file }) => file))).toEqual(new Set(["tokens.css"]));
    expect(Object.fromEntries(declarations.map(({ name, value }) => [name, value]))).toEqual(expectedTokens);
  });

  it("keeps cognitura.css as the exact closed four-import graph", () => {
    expect(cognituraCss).toBe(
      '@import "./tokens.css";\n@import "./typography.css";\n@import "./surfaces.css";\n@import "./cognitive-visual.css";\n',
    );
  });

  it("projects only the approved typography roles, stack, weights, and scale", () => {
    const roleClasses = [...typographyCss.matchAll(/\.([a-z0-9-]+)\s*\{/g)].map(([, name]) => name);
    expect(roleClasses).toEqual([
      "cka-visual-root",
      "cka-type-page-title",
      "cka-type-object-title",
      "cka-type-major-section",
      "cka-type-cognitive-section",
      "cka-type-reading",
      "cka-type-ui",
      "cka-type-metadata",
      "cka-type-caption",
    ]);
    expect(blockFor(typographyCss, ".cka-visual-root")).toContain("font-family: var(--font-interface)");
    expect(blockFor(typographyCss, ".cka-type-reading")).toMatch(
      /font-size:\s*var\(--type-reading-size\);[\s\S]*line-height:\s*var\(--type-reading-line-height\);/,
    );
    expect(expectedTokens["--type-reading-size"]).toBe("16px");
    expect(expectedTokens["--type-reading-line-height"]).toBe("27px");
    expect(
      declarations.filter(({ name }) => name.startsWith("--font-weight-")).map(({ value }) => value),
    ).toEqual(["400", "500", "600", "700"]);
  });

  it("keeps reading unshadowed and makes projection border-first", () => {
    const reading = blockFor(surfacesCss, ".cka-reading-surface");
    const projection = blockFor(surfacesCss, ".cka-projection-surface");
    expect(reading).toMatch(/box-shadow:\s*none;/);
    expect(projection).toMatch(/border:\s*1px solid var\(--border-subtle\);/);
    expect(projection).toMatch(/box-shadow:\s*var\(--shadow-xs\);/);
    expect(projection.indexOf("border:")).toBeLessThan(projection.indexOf("box-shadow:"));
    expect(blockFor(surfacesCss, ".cka-semantic-boundary")).toMatch(
      /border-inline-start:[^;]+;[\s\S]*background(?:-color)?:\s*var\(--color-warning-soft\);/,
    );
  });

  it("exposes the approved focus fallback and focus-visible ring", () => {
    const focus = blockFor(cognitiveVisualCss, ".cka-focusable:focus-visible");
    expect(cognitiveVisualCss).toContain(".cka-focusable:focus,");
    expect(focus).toMatch(
      /outline:\s*var\(--focus-ring-width\) solid var\(--focus-ring-color\);/,
    );
    expect(focus).toMatch(/outline-offset:\s*var\(--focus-ring-offset\);/);
    expect(expectedTokens["--focus-ring-width"]).toBe("2px");
    expect(expectedTokens["--focus-ring-offset"]).toBe("2px");
    expect(expectedTokens["--focus-ring-color"]).toBe("rgb(79 103 232 / 32%)");
  });

  it("forbids template-style names, remote assets, gradients, glass, glow, and colored shadows", () => {
    const allCss = Object.values(styles).join("\n");
    expect(allCss).not.toMatch(/--[^:;{}]*(?:blue-|purple-card|green-box|gradient|glass|card-wall)/i);
    expect(allCss).not.toMatch(/url\s*\(\s*["']?(?:https?:)?\/\//i);
    expect(allCss).not.toMatch(/backdrop-filter|(?:repeating-)?(?:linear|radial|conic)-gradient|\bglow\b/i);
    const shadows = [...allCss.matchAll(/box-shadow\s*:\s*([^;]+);/g)].map(([, value]) => value.trim());
    expect(shadows).toEqual(expect.arrayContaining(["none", "var(--shadow-xs)"]));
    expect(shadows.every((value) => value === "none" || /^var\(--shadow-(?:xs|sm|md)\)$/.test(value))).toBe(true);
  });

  it("uses verb, direction, endpoint, and line-style relation hooks instead of color-only types", () => {
    for (const selector of [
      ".cka-relation-statement",
      ".cka-relation-verb",
      ".cka-relation-direction",
      ".cka-relation-direction::after",
      ".cka-relation-endpoint",
      '.cka-relation-statement[data-relation-strength="weak"] .cka-relation-direction',
    ]) {
      blockFor(cognitiveVisualCss, selector);
    }
    expect(cognitiveVisualCss).toMatch(/border-block-start-style:\s*dashed;/);
    expect(cognitiveVisualCss).not.toMatch(/data-relation-type|relation-(?:causes|depends|supports|contrasts)/i);
    expect(
      [...cognitiveVisualCss.matchAll(/\.(cka-status-[a-z-]+)\s*\{/g)].map(([, name]) => name),
    ).toEqual([
      "cka-status-confirmed",
      "cka-status-focus",
      "cka-status-warning",
      "cka-status-conflict",
    ]);
  });
});
