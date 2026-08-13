import { describe, expect, it } from "vitest";

import cognitiveVisualRaw from "./cognitive-visual.css?raw";
import cognituraRaw from "./cognitura.css?raw";
import surfacesRaw from "./surfaces.css?raw";
import tokensRaw from "./tokens.css?raw";
import typographyRaw from "./typography.css?raw";

const nodeFsModule = "node:fs";
const { readFileSync } = await import(nodeFsModule);

const readRawCss = (rawImport: string, relativePath: string) =>
  rawImport || readFileSync(new URL(relativePath, import.meta.url), "utf8");

const cognitiveVisualCss = readRawCss(cognitiveVisualRaw, "./cognitive-visual.css");
const cognituraCss = readRawCss(cognituraRaw, "./cognitura.css");
const surfacesCss = readRawCss(surfacesRaw, "./surfaces.css");
const tokensCss = readRawCss(tokensRaw, "./tokens.css");
const typographyCss = readRawCss(typographyRaw, "./typography.css");

const styles = {
  "tokens.css": tokensCss,
  "typography.css": typographyCss,
  "surfaces.css": surfacesCss,
  "cognitive-visual.css": cognitiveVisualCss,
  "cognitura.css": cognituraCss,
} as const;

type StyleFile = keyof typeof styles;
type StyleSet = Record<StyleFile, string>;

const approvedSelectorsByFile: Record<StyleFile, string[]> = {
  "tokens.css": [":root"],
  "typography.css": [
    ".cka-visual-root",
    ".cka-type-page-title",
    ".cka-type-object-title",
    ".cka-type-major-section",
    ".cka-type-cognitive-section",
    ".cka-type-reading",
    ".cka-type-ui",
    ".cka-type-metadata",
    ".cka-type-caption",
  ],
  "surfaces.css": [
    ".cka-canvas",
    ".cka-reading-surface",
    ".cka-projection-surface",
    ".cka-subtle-band",
    ".cka-semantic-boundary",
  ],
  "cognitive-visual.css": [
    ".cka-focusable:focus, .cka-focusable:focus-visible",
    ".cka-relation-statement",
    ".cka-relation-verb",
    ".cka-relation-direction",
    ".cka-relation-direction::after",
    ".cka-relation-endpoint",
    '.cka-relation-statement[data-relation-strength="weak"] .cka-relation-direction',
    ".cka-status-confirmed",
    ".cka-status-focus",
    ".cka-status-warning",
    ".cka-status-conflict",
  ],
  "cognitura.css": [],
};

const stripCssComments = (css: string) => {
  let activeCss = "";
  let quote: '"' | "'" | null = null;

  for (let index = 0; index < css.length; index += 1) {
    const character = css[index];
    const nextCharacter = css[index + 1];

    if (quote !== null) {
      activeCss += character;
      if (character === "\\" && nextCharacter !== undefined) {
        activeCss += nextCharacter;
        index += 1;
      } else if (character === quote) {
        quote = null;
      }
      continue;
    }

    if (character === '"' || character === "'") {
      quote = character;
      activeCss += character;
      continue;
    }

    if (character === "/" && nextCharacter === "*") {
      activeCss += " ";
      index += 2;
      while (index < css.length && !(css[index] === "*" && css[index + 1] === "/")) {
        if (css[index] === "\n") activeCss += "\n";
        index += 1;
      }
      if (index >= css.length) throw new Error("unterminated CSS comment");
      index += 1;
      continue;
    }

    activeCss += character;
  }

  return activeCss;
};

const activeCssFor = (candidateStyles: StyleSet): StyleSet =>
  Object.fromEntries(
    Object.entries(candidateStyles).map(([file, css]) => [file, stripCssComments(css)]),
  ) as StyleSet;

const normalizeSelector = (selector: string) =>
  selector
    .split(",")
    .map((part) => part.trim().replace(/\s+/g, " "))
    .join(", ");

type ParsedStyleSheet = {
  imports: string[];
  rules: Array<{ selector: string; body: string; declarations: ParsedDeclaration[] }>;
};

type ParsedDeclaration = { property: string; value: string };

const parseActiveDeclarations = (body: string): ParsedDeclaration[] => {
  const declarations: ParsedDeclaration[] = [];
  let cursor = 0;

  while (cursor < body.length) {
    while (/\s/.test(body[cursor] ?? "")) cursor += 1;
    if (cursor >= body.length) break;

    const propertyStart = cursor;
    while (cursor < body.length && body[cursor] !== ":") {
      if (';{}()"\''.includes(body[cursor])) throw new Error("invalid CSS declaration property");
      cursor += 1;
    }
    if (cursor >= body.length) throw new Error("unterminated CSS declaration");

    const property = body.slice(propertyStart, cursor).trim();
    if (!/^(?:--[a-z0-9-]+|[a-z][a-z0-9-]*)$/.test(property)) {
      throw new Error(`invalid CSS declaration property: ${property}`);
    }
    cursor += 1;

    const valueStart = cursor;
    let quote: '"' | "'" | null = null;
    let parenthesesDepth = 0;
    while (cursor < body.length) {
      const character = body[cursor];
      const nextCharacter = body[cursor + 1];

      if (quote !== null) {
        if (character === "\\" && nextCharacter !== undefined) {
          cursor += 2;
          continue;
        }
        if (character === quote) quote = null;
        cursor += 1;
        continue;
      }

      if (character === '"' || character === "'") {
        quote = character;
        cursor += 1;
        continue;
      }
      if (character === "(") {
        parenthesesDepth += 1;
        cursor += 1;
        continue;
      }
      if (character === ")") {
        if (parenthesesDepth === 0) throw new Error("unmatched CSS parenthesis");
        parenthesesDepth -= 1;
        cursor += 1;
        continue;
      }
      if (character === "{" || character === "}") throw new Error("invalid CSS declaration value");
      if (character === ";" && parenthesesDepth === 0) break;
      cursor += 1;
    }

    if (quote !== null) throw new Error("unterminated CSS string");
    if (parenthesesDepth !== 0) throw new Error("unterminated CSS parentheses");
    if (cursor >= body.length) throw new Error("unterminated CSS declaration");

    const value = normalizeValue(body.slice(valueStart, cursor));
    if (value.length === 0) throw new Error(`empty CSS declaration value: ${property}`);
    declarations.push({ property, value });
    cursor += 1;
  }

  return declarations;
};

const findOutsideString = (css: string, start: number, targets: string[]) => {
  let quote: '"' | "'" | null = null;
  for (let index = start; index < css.length; index += 1) {
    const character = css[index];
    if (quote !== null) {
      if (character === "\\") index += 1;
      else if (character === quote) quote = null;
      continue;
    }
    if (character === '"' || character === "'") quote = character;
    else if (targets.includes(character)) return index;
  }
  return -1;
};

const parseActiveStyleSheet = (activeCss: string): ParsedStyleSheet => {
  const imports: string[] = [];
  const rules: ParsedStyleSheet["rules"] = [];
  let cursor = 0;

  while (cursor < activeCss.length) {
    while (/\s/.test(activeCss[cursor] ?? "")) cursor += 1;
    if (cursor >= activeCss.length) break;

    if (activeCss[cursor] === "@") {
      const atRuleMatch = activeCss.slice(cursor).match(/^@([a-z-]+)/i);
      if (!atRuleMatch) throw new Error("invalid CSS at-rule");
      if (atRuleMatch[1].toLowerCase() !== "import") {
        throw new Error(`unknown CSS at-rule: @${atRuleMatch[1]}`);
      }
      const semicolon = findOutsideString(activeCss, cursor, [";"]);
      if (semicolon < 0) throw new Error("unterminated CSS import");
      imports.push(activeCss.slice(cursor, semicolon + 1).trim().replace(/\s+/g, " "));
      cursor = semicolon + 1;
      continue;
    }

    const openingBrace = findOutsideString(activeCss, cursor, ["{", ";"]);
    if (openingBrace < 0 || activeCss[openingBrace] !== "{") {
      throw new Error("invalid CSS rule");
    }
    const selector = normalizeSelector(activeCss.slice(cursor, openingBrace));
    if (selector.length === 0) throw new Error("empty CSS selector");

    const closingBrace = findOutsideString(activeCss, openingBrace + 1, ["{", "}"]);
    if (closingBrace < 0) throw new Error(`unterminated CSS rule: ${selector}`);
    if (activeCss[closingBrace] === "{") throw new Error(`nested CSS rule: ${selector}`);

    const body = activeCss.slice(openingBrace + 1, closingBrace);
    rules.push({ selector, body, declarations: parseActiveDeclarations(body) });
    cursor = closingBrace + 1;
  }

  return { imports, rules };
};

const expectedImportsByFile: Record<StyleFile, string[]> = {
  "tokens.css": [],
  "typography.css": [],
  "surfaces.css": [],
  "cognitive-visual.css": [],
  "cognitura.css": [
    '@import "./tokens.css";',
    '@import "./typography.css";',
    '@import "./surfaces.css";',
    '@import "./cognitive-visual.css";',
  ],
};

const parseClosedStyleSet = (candidateStyles: StyleSet) => {
  const activeStyles = activeCssFor(candidateStyles);
  const parsed = Object.fromEntries(
    Object.entries(activeStyles).map(([file, css]) => [file, parseActiveStyleSheet(css)]),
  ) as Record<StyleFile, ParsedStyleSheet>;

  for (const file of Object.keys(candidateStyles) as StyleFile[]) {
    const selectors = parsed[file].rules.map(({ selector }) => selector);
    if (JSON.stringify(selectors) !== JSON.stringify(approvedSelectorsByFile[file])) {
      throw new Error(`CSS selector set is not closed: ${file}`);
    }
    if (new Set(selectors).size !== selectors.length) {
      throw new Error(`duplicate CSS selector: ${file}`);
    }
    if (JSON.stringify(parsed[file].imports) !== JSON.stringify(expectedImportsByFile[file])) {
      throw new Error(`CSS import set is not closed: ${file}`);
    }
    if (
      JSON.stringify(Object.keys(expectedDeclarationsByFile[file])) !==
      JSON.stringify(approvedSelectorsByFile[file])
    ) {
      throw new Error(`declaration authority is not closed: ${file}`);
    }
    for (const rule of parsed[file].rules) {
      const properties = rule.declarations.map(({ property }) => property);
      if (new Set(properties).size !== properties.length) {
        throw new Error(`duplicate CSS declaration: ${file} ${rule.selector}`);
      }
      if (
        JSON.stringify(rule.declarations) !==
        JSON.stringify(expectedDeclarationsByFile[file][rule.selector])
      ) {
        throw new Error(`CSS declarations differ from authority: ${file} ${rule.selector}`);
      }
    }
  }

  return { activeStyles, parsed };
};

const styleContractAccepts = (candidateStyles: StyleSet) => {
  try {
    const { parsed } = parseClosedStyleSet(candidateStyles);
    const allDeclarations = Object.entries(parsed).flatMap(([file, sheet]) =>
      sheet.rules.flatMap(({ declarations }) =>
        declarations.map(({ property, value }) => ({ file, property, value })),
      ),
    );
    const candidateDeclarations = allDeclarations
      .filter(({ property }) => property.startsWith("--"))
      .map(({ file, property, value }) => ({ file, name: property, value }));
    if (candidateDeclarations.length !== Object.keys(expectedTokens).length) return false;
    if (new Set(candidateDeclarations.map(({ name }) => name)).size !== candidateDeclarations.length) {
      return false;
    }
    if (candidateDeclarations.some(({ file }) => file !== "tokens.css")) return false;
    if (
      JSON.stringify(
        Object.fromEntries(candidateDeclarations.map(({ name, value }) => [name, value])),
      ) !== JSON.stringify(expectedTokens)
    ) {
      return false;
    }

    const activeDeclarations = allDeclarations
      .map(({ property, value }) => `${property}: ${value}`)
      .join("\n");
    return !/--[^:;{}]*(?:blue-|purple-card|green-box|gradient|glass|card-wall)|url\s*\(\s*["']?(?:https?:)?\/\/|backdrop-filter|(?:repeating-)?(?:linear|radial|conic)-gradient|\bglow\b/i.test(
      activeDeclarations,
    );
  } catch {
    return false;
  }
};

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

const expectedDeclarationsByFile: Record<StyleFile, Record<string, ParsedDeclaration[]>> = {
  "tokens.css": {
    ":root": [
      { property: "color-scheme", value: "light" },
      ...Object.entries(expectedTokens).map(([property, value]) => ({ property, value })),
    ],
  },
  "typography.css": {
    ".cka-visual-root": [
      { property: "color", value: "var(--text-primary)" },
      { property: "font-family", value: "var(--font-interface)" },
      { property: "font-size", value: "var(--type-reading-size)" },
      { property: "line-height", value: "var(--type-reading-line-height)" },
      { property: "text-rendering", value: "optimizeLegibility" },
    ],
    ".cka-type-page-title": [
      { property: "font-size", value: "var(--type-page-title-size)" },
      { property: "line-height", value: "var(--type-page-title-line-height)" },
      { property: "font-weight", value: "var(--font-weight-bold)" },
    ],
    ".cka-type-object-title": [
      { property: "font-size", value: "var(--type-object-title-size)" },
      { property: "line-height", value: "var(--type-object-title-line-height)" },
      { property: "font-weight", value: "var(--font-weight-semibold)" },
    ],
    ".cka-type-major-section": [
      { property: "font-size", value: "var(--type-major-section-size)" },
      { property: "line-height", value: "var(--type-major-section-line-height)" },
      { property: "font-weight", value: "var(--font-weight-semibold)" },
    ],
    ".cka-type-cognitive-section": [
      { property: "font-size", value: "var(--type-cognitive-section-size)" },
      { property: "line-height", value: "var(--type-cognitive-section-line-height)" },
      { property: "font-weight", value: "var(--font-weight-semibold)" },
    ],
    ".cka-type-reading": [
      { property: "font-size", value: "var(--type-reading-size)" },
      { property: "line-height", value: "var(--type-reading-line-height)" },
      { property: "font-weight", value: "var(--font-weight-regular)" },
    ],
    ".cka-type-ui": [
      { property: "font-size", value: "var(--type-ui-size)" },
      { property: "line-height", value: "var(--type-ui-line-height)" },
    ],
    ".cka-type-metadata": [
      { property: "font-size", value: "var(--type-metadata-size)" },
      { property: "line-height", value: "var(--type-metadata-line-height)" },
    ],
    ".cka-type-caption": [
      { property: "font-size", value: "var(--type-caption-size)" },
      { property: "line-height", value: "var(--type-caption-line-height)" },
    ],
  },
  "surfaces.css": {
    ".cka-canvas": [
      { property: "min-block-size", value: "100%" },
      { property: "background", value: "var(--color-canvas)" },
    ],
    ".cka-reading-surface": [
      { property: "box-sizing", value: "border-box" },
      { property: "inline-size", value: "min(100%, var(--reading-column-width))" },
      { property: "margin-inline", value: "auto" },
      { property: "background", value: "var(--surface-reading)" },
      { property: "box-shadow", value: "none" },
    ],
    ".cka-projection-surface": [
      { property: "box-sizing", value: "border-box" },
      { property: "inline-size", value: "min(100%, var(--projection-width))" },
      { property: "border", value: "1px solid var(--border-subtle)" },
      { property: "border-radius", value: "var(--radius-lg)" },
      { property: "background", value: "var(--surface-projection)" },
      { property: "box-shadow", value: "var(--shadow-xs)" },
    ],
    ".cka-subtle-band": [
      { property: "border-block", value: "1px solid var(--border-subtle)" },
      { property: "background", value: "var(--surface-subtle)" },
    ],
    ".cka-semantic-boundary": [
      { property: "border-inline-start", value: "3px solid var(--color-warning)" },
      { property: "border-radius", value: "var(--radius-sm)" },
      { property: "background", value: "var(--color-warning-soft)" },
      { property: "padding", value: "var(--space-4)" },
    ],
  },
  "cognitive-visual.css": {
    ".cka-focusable:focus, .cka-focusable:focus-visible": [
      {
        property: "outline",
        value: "var(--focus-ring-width) solid var(--focus-ring-color)",
      },
      { property: "outline-offset", value: "var(--focus-ring-offset)" },
    ],
    ".cka-relation-statement": [
      { property: "display", value: "grid" },
      {
        property: "grid-template-columns",
        value: "minmax(0, 1fr) auto minmax(0, 1fr)",
      },
      { property: "align-items", value: "center" },
      { property: "color", value: "var(--text-secondary)" },
    ],
    ".cka-relation-verb": [
      { property: "color", value: "var(--color-primary)" },
      { property: "font-weight", value: "var(--font-weight-semibold)" },
    ],
    ".cka-relation-direction": [
      { property: "position", value: "relative" },
      { property: "min-inline-size", value: "var(--space-12)" },
      { property: "border-block-start", value: "1.5px solid currentColor" },
    ],
    ".cka-relation-direction::after": [
      { property: "position", value: "absolute" },
      { property: "inset-block-start", value: "-4px" },
      { property: "inset-inline-end", value: "0" },
      { property: "inline-size", value: "6px" },
      { property: "block-size", value: "6px" },
      { property: "border", value: "solid currentColor" },
      { property: "border-width", value: "0 1.5px 1.5px 0" },
      { property: "content", value: '""' },
      { property: "transform", value: "rotate(-45deg)" },
    ],
    ".cka-relation-endpoint": [
      { property: "min-inline-size", value: "0" },
      { property: "color", value: "var(--text-primary)" },
    ],
    '.cka-relation-statement[data-relation-strength="weak"] .cka-relation-direction': [
      { property: "border-block-start-style", value: "dashed" },
      { property: "opacity", value: "0.64" },
    ],
    ".cka-status-confirmed": [
      { property: "color", value: "var(--color-success)" },
      { property: "background", value: "var(--color-success-soft)" },
    ],
    ".cka-status-focus": [
      { property: "color", value: "var(--color-focus)" },
      { property: "background", value: "var(--color-focus-soft)" },
    ],
    ".cka-status-warning": [
      { property: "color", value: "var(--color-warning)" },
      { property: "background", value: "var(--color-warning-soft)" },
    ],
    ".cka-status-conflict": [
      { property: "color", value: "var(--color-danger)" },
      { property: "background", value: "var(--color-danger-soft)" },
    ],
  },
  "cognitura.css": {},
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

const normalizeValue = (value: string) => {
  let normalized = "";
  let quote: '"' | "'" | null = null;
  let pendingSpace = false;

  for (let index = 0; index < value.length; index += 1) {
    const character = value[index];
    const nextCharacter = value[index + 1];

    if (quote !== null) {
      normalized += character;
      if (character === "\\" && nextCharacter !== undefined) {
        normalized += nextCharacter;
        index += 1;
      } else if (character === quote) {
        quote = null;
      }
      continue;
    }

    if (character === '"' || character === "'") {
      if (pendingSpace && normalized.length > 0) normalized += " ";
      pendingSpace = false;
      quote = character;
      normalized += character;
      continue;
    }

    if (/\s/.test(character)) {
      pendingSpace = true;
      continue;
    }

    if (pendingSpace && normalized.length > 0) normalized += " ";
    pendingSpace = false;

    const hex = value.slice(index).match(/^#[0-9A-F]{6}\b/);
    if (hex) {
      normalized += hex[0].toLowerCase();
      index += hex[0].length - 1;
    } else {
      normalized += character;
    }
  }

  if (quote !== null) throw new Error("unterminated CSS string");
  return normalized;
};

const { activeStyles: activeCssByFile, parsed: parsedCssByFile } = parseClosedStyleSet(styles);

const declarations = Object.entries(parsedCssByFile).flatMap(([file, sheet]) =>
  sheet.rules.flatMap(({ declarations: ruleDeclarations }) =>
    ruleDeclarations
      .filter(({ property }) => property.startsWith("--"))
      .map(({ property, value }) => ({ file, name: property, value })),
  ),
);

const blockFor = (css: string, selector: string) => {
  const normalizedSelector = normalizeSelector(selector);
  const matches = parseActiveStyleSheet(css).rules.filter(
    ({ selector: candidateSelector }) =>
      candidateSelector === normalizedSelector ||
      candidateSelector.split(", ").includes(normalizedSelector),
  );
  expect(matches, `missing or duplicate CSS rule for ${selector}`).toHaveLength(1);
  return matches[0]?.body ?? "";
};

describe("Cognitura semantic style contract", () => {
  it("rejects token-shaped text inside a declaration string", () => {
    const tokenText = Object.entries(expectedTokens)
      .map(([name, value]) => `${name}: ${value};`)
      .join("\\a ");
    expect(
      styleContractAccepts({
        ...styles,
        "tokens.css": `:root { content: '${tokenText}'; }`,
      }),
    ).toBe(false);
  });

  it("rejects duplicate, unknown, missing, and drifting declarations in approved blocks", () => {
    expect(
      styleContractAccepts({
        ...styles,
        "surfaces.css": surfacesCss.replace(
          "  box-shadow: none;",
          "  box-shadow: none;\n  box-shadow: var(--shadow-md);",
        ),
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "surfaces.css": surfacesCss.replace(
          "  box-shadow: none;",
          "  box-shadow: none;\n  filter: none;",
        ),
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "surfaces.css": surfacesCss.replace("  box-shadow: none;\n", ""),
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "surfaces.css": surfacesCss.replace(
          "  background: var(--surface-reading);",
          "  background: var(--surface-projection);",
        ),
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "tokens.css": tokensCss.replace("color-scheme: light;", "color-scheme: light dark;"),
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "tokens.css": tokensCss.replace(
          "color-scheme: light;",
          "color-scheme: light-dark(light, dark);",
        ),
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "cognitive-visual.css": cognitiveVisualCss.replace(
          "  border-block-start: 1.5px solid currentColor;",
          "  border-block-start: 1.5px solid currentColor;\n  border-block-start: 8px dotted currentColor;",
        ),
      }),
    ).toBe(false);
  });

  it("parses declaration strings, escapes, parentheses, and semicolons structurally", () => {
    expect(
      parseActiveDeclarations(
        'content: "semi;paren ( and  \\"quote\\" )"; background: rgb(1 2 3 / calc(50% + 1%));',
      ),
    ).toEqual([
      { property: "content", value: '"semi;paren ( and  \\"quote\\" )"' },
      { property: "background", value: "rgb(1 2 3 / calc(50% + 1%))" },
    ]);
    expect(() => parseActiveDeclarations('content: "unterminated;')).toThrow(
      "unterminated CSS string",
    );
    expect(() => parseActiveDeclarations("color: rgb(1 2 3 / 50%;")).toThrow(
      "unterminated CSS parentheses",
    );
    expect(() => parseActiveStyleSheet(".rule { color: red;")).toThrow(
      "unterminated CSS rule",
    );
  });

  it("rejects declarations and selectors hidden inside CSS comments", () => {
    expect(styleContractAccepts(styles)).toBe(true);
    expect(
      styleContractAccepts({
        ...styles,
        "tokens.css": `/*${tokensCss}*/`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "tokens.css": `${tokensCss}\n/* @import "https://example.invalid/theme.css"; [data-theme="dark"] { --surface-reading: linear-gradient(red, blue); } */\n`,
      }),
    ).toBe(true);
    expect(
      styleContractAccepts({
        ...styles,
        "tokens.css": `${tokensCss}\n/* unterminated`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "typography.css": `/*${typographyCss}*/`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "cognitive-visual.css": `/*${cognitiveVisualCss}*/`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "cognitura.css": `/*${cognituraCss}*/`,
      }),
    ).toBe(false);
  });

  it("rejects duplicate approved selectors that override semantic rules", () => {
    expect(
      styleContractAccepts({
        ...styles,
        "surfaces.css": `${surfacesCss}\n.cka-reading-surface { background: red; box-shadow: var(--shadow-md); }\n`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "cognitive-visual.css": `${cognitiveVisualCss}\n.cka-relation-direction { border-block-start: 8px dotted currentColor; }\n`,
      }),
    ).toBe(false);
  });

  it("rejects second themes, active at-rules, unknown selectors, and remote imports", () => {
    expect(
      styleContractAccepts({
        ...styles,
        "surfaces.css": `${surfacesCss}\n@media (prefers-color-scheme: dark) { :root { --surface-reading: #000000; } }\n`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "tokens.css": `${tokensCss}\n[data-theme="dark"] { --surface-reading: #000000; }\n`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "cognitura.css": `${cognituraCss}@import "https://example.invalid/theme.css";\n`,
      }),
    ).toBe(false);
    expect(
      styleContractAccepts({
        ...styles,
        "surfaces.css": `${surfacesCss}\n.unknown-surface { background: var(--surface-reading); }\n`,
      }),
    ).toBe(false);
  });

  it("strips comment boundaries, preserves comment markers in strings, and fails closed", () => {
    expect(stripCssComments(".left/* boundary */.right {}")).toBe(".left .right {}");
    expect(stripCssComments('.rule { content: "/* literal */"; }')).toBe(
      '.rule { content: "/* literal */"; }',
    );
    expect(() => stripCssComments(".rule { color: red; /* unterminated")).toThrow(
      "unterminated CSS comment",
    );
  });

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
    expect(parsedCssByFile["cognitura.css"].imports).toEqual(
      expectedImportsByFile["cognitura.css"],
    );
    expect(parsedCssByFile["cognitura.css"].rules).toHaveLength(0);
    for (const file of Object.keys(styles) as StyleFile[]) {
      if (file !== "cognitura.css") expect(parsedCssByFile[file].imports).toHaveLength(0);
    }
  });

  it("projects only the approved typography roles, stack, weights, and scale", () => {
    expect(parsedCssByFile["typography.css"].rules.map(({ selector }) => selector)).toEqual([
      ".cka-visual-root",
      ".cka-type-page-title",
      ".cka-type-object-title",
      ".cka-type-major-section",
      ".cka-type-cognitive-section",
      ".cka-type-reading",
      ".cka-type-ui",
      ".cka-type-metadata",
      ".cka-type-caption",
    ]);
    expect(blockFor(activeCssByFile["typography.css"], ".cka-visual-root")).toContain(
      "font-family: var(--font-interface)",
    );
    expect(blockFor(activeCssByFile["typography.css"], ".cka-type-reading")).toMatch(
      /font-size:\s*var\(--type-reading-size\);[\s\S]*line-height:\s*var\(--type-reading-line-height\);/,
    );
    expect(expectedTokens["--type-reading-size"]).toBe("16px");
    expect(expectedTokens["--type-reading-line-height"]).toBe("27px");
    expect(
      declarations.filter(({ name }) => name.startsWith("--font-weight-")).map(({ value }) => value),
    ).toEqual(["400", "500", "600", "700"]);
  });

  it("keeps reading unshadowed and makes projection border-first", () => {
    const reading = blockFor(activeCssByFile["surfaces.css"], ".cka-reading-surface");
    const projection = blockFor(activeCssByFile["surfaces.css"], ".cka-projection-surface");
    expect(reading).toMatch(/box-shadow:\s*none;/);
    expect(projection).toMatch(/border:\s*1px solid var\(--border-subtle\);/);
    expect(projection).toMatch(/box-shadow:\s*var\(--shadow-xs\);/);
    expect(projection.indexOf("border:")).toBeLessThan(projection.indexOf("box-shadow:"));
    expect(blockFor(activeCssByFile["surfaces.css"], ".cka-semantic-boundary")).toMatch(
      /border-inline-start:[^;]+;[\s\S]*background(?:-color)?:\s*var\(--color-warning-soft\);/,
    );
  });

  it("exposes the approved focus fallback and focus-visible ring", () => {
    const focus = blockFor(activeCssByFile["cognitive-visual.css"], ".cka-focusable:focus-visible");
    expect(activeCssByFile["cognitive-visual.css"]).toContain(".cka-focusable:focus,");
    expect(focus).toMatch(
      /outline:\s*var\(--focus-ring-width\) solid var\(--focus-ring-color\);/,
    );
    expect(focus).toMatch(/outline-offset:\s*var\(--focus-ring-offset\);/);
    expect(expectedTokens["--focus-ring-width"]).toBe("2px");
    expect(expectedTokens["--focus-ring-offset"]).toBe("2px");
    expect(expectedTokens["--focus-ring-color"]).toBe("rgb(79 103 232 / 32%)");
  });

  it("forbids template-style names, remote assets, gradients, glass, glow, and colored shadows", () => {
    const allCss = Object.values(activeCssByFile).join("\n");
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
      blockFor(activeCssByFile["cognitive-visual.css"], selector);
    }
    expect(activeCssByFile["cognitive-visual.css"]).toMatch(/border-block-start-style:\s*dashed;/);
    expect(activeCssByFile["cognitive-visual.css"]).not.toMatch(
      /data-relation-type|relation-(?:causes|depends|supports|contrasts)/i,
    );
    expect(
      parsedCssByFile["cognitive-visual.css"].rules
        .map(({ selector }) => selector.match(/^\.(cka-status-[a-z-]+)$/)?.[1])
        .filter((name): name is string => name !== undefined),
    ).toEqual([
      "cka-status-confirmed",
      "cka-status-focus",
      "cka-status-warning",
      "cka-status-conflict",
    ]);
  });
});
