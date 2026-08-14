import {
  cleanup,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import viteConfigRaw from "../../vite.config.mjs?raw";
import visualReferenceHtml from "../../visual-reference.html?raw";
import fixtureRaw from "./module-default-reading.fixture.ts?raw";
import {
  buildVisualReferenceNodes,
  visualReferenceModule,
  visualReferenceRenderer,
} from "./module-default-reading.fixture";
import mainRaw from "./main.tsx?raw";
import { findVisualReferenceRoot, VisualReference } from "./VisualReference";
import visualReferenceRaw from "./VisualReference.tsx?raw";
import visualReferenceCss from "./visual-reference.css?raw";

const nodeFsModule = "node:fs";
const { readFileSync } = await import(nodeFsModule);
const readRaw = (rawImport: string, relativePath: string) =>
  rawImport || readFileSync(new URL(relativePath, import.meta.url), "utf8");
const viteConfigSource = readRaw(viteConfigRaw, "../../vite.config.mjs");
const visualReferenceDocument = readRaw(
  visualReferenceHtml,
  "../../visual-reference.html",
);
const fixtureSource = readRaw(
  fixtureRaw,
  "./module-default-reading.fixture.ts",
);
const mainSource = readRaw(mainRaw, "./main.tsx");
const visualReferenceSource = readRaw(
  visualReferenceRaw,
  "./VisualReference.tsx",
);
const visualReferenceStyles = readRaw(
  visualReferenceCss,
  "./visual-reference.css",
);
const optionalMethodRestorers: Array<() => void> = [];

const forbiddenFixtureBehaviors = [
  /raw\//,
  /https?:\/\//,
  /\bfetch\s*\(/,
  /\bXMLHttpRequest\b/,
  /\bWebSocket\b/,
  /\bEventSource\b/,
  /\bsendBeacon\b/,
  /\blocalStorage\b/,
  /\bsessionStorage\b/,
  /\bindexedDB\b/,
  /document\.cookie/,
  /navigator\.storage/,
  /\b<App\b/,
  /\b(?:createBrowserRouter|useNavigate|useRoutes|RouterProvider)\b/,
] as const;

const forbiddenProjectionName = /^(?:conditions|results)$/i;
const forbiddenProjectionClassToken =
  /(?:^|[-_])(?:conditions?|results?)(?:$|[-_])/i;
const forbiddenDashboardClassFragment =
  /(?:dashboard|card-wall|metric|coverage|progress|glass|gradient)/i;

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  optionalMethodRestorers.splice(0).reverse().forEach((restore) => restore());
});

function replaceOptionalMethod(
  target: object,
  property: PropertyKey,
  replacement: unknown,
) {
  const previousDescriptor = Object.getOwnPropertyDescriptor(target, property);
  Object.defineProperty(target, property, {
    configurable: true,
    value: replacement,
  });
  const restore = () => {
    if (previousDescriptor === undefined) {
      Reflect.deleteProperty(target, property);
    } else {
      Object.defineProperty(target, property, previousDescriptor);
    }
  };
  optionalMethodRestorers.push(restore);
  return restore;
}

function expectNoConditionsOrResults(root: HTMLElement) {
  expect(
    within(root).queryByRole("heading", {
      name: /^(?:Conditions|Results)$/i,
    }),
  ).toBeNull();
  expect(
    root.querySelectorAll(
      '[data-reading-section="conditions"], [data-reading-section="results"]',
    ),
  ).toHaveLength(0);
  const ariaSections = Array.from(
    root.querySelectorAll<HTMLElement>(
      'section[aria-label], [role="region"][aria-label]',
    ),
  ).filter((section) =>
    forbiddenProjectionName.test(section.getAttribute("aria-label")?.trim() ?? ""),
  );
  expect(ariaSections).toHaveLength(0);
  const classSections = Array.from(
    root.querySelectorAll<HTMLElement>("section[class]"),
  ).filter((section) =>
    Array.from(section.classList).some((token) =>
      forbiddenProjectionClassToken.test(token),
    ),
  );
  expect(classSections).toHaveLength(0);
}

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

function expectSmallScreenBreadcrumbPaddingContract(source: string) {
  expect(source).toMatch(
    /@media\s*\(max-width:\s*48rem\)[\s\S]*?\.visual-reference__path\s*\{[^}]*padding-inline:\s*var\(--space-5\)/,
  );
}

function computedBreadcrumbBoxSizing(source: string) {
  const style = document.createElement("style");
  style.textContent = source;
  document.head.append(style);
  const { container, unmount } = render(<VisualReference />);
  const breadcrumb = within(container).getByRole("navigation", {
    name: "知识路径",
  });
  const boxSizing = getComputedStyle(breadcrumb).boxSizing;
  unmount();
  style.remove();
  return boxSizing;
}

function expectBreadcrumbBorderBox(source: string) {
  expect(computedBreadcrumbBoxSizing(source)).toBe("border-box");
}

function expectOfflineFixtureSources(sources: readonly string[]) {
  sources.forEach((source) =>
    forbiddenFixtureBehaviors.forEach((pattern) =>
      expect(source).not.toMatch(pattern),
    ),
  );
  sources.flatMap(importSourcesFrom).forEach((source) =>
    expect(isProductIntegrationImport(source)).toBe(false),
  );
}

function importSourcesFrom(source: string) {
  const imports = new Set<string>();
  const patterns = [
    /\bfrom\s*["']([^"']+)["']/g,
    /\bimport\s*(?:\(\s*)?["']([^"']+)["']/g,
  ];
  patterns.forEach((pattern) => {
    for (const match of source.matchAll(pattern)) imports.add(match[1]);
  });
  return [...imports];
}

function isProductIntegrationImport(source: string) {
  const suffixIndex = source.slice(1).search(/[?#]/);
  const normalizedPath = (suffixIndex < 0
    ? source
    : source.slice(0, suffixIndex + 1)
  ).replaceAll("\\", "/");
  return normalizedPath
    .split("/")
    .filter(Boolean)
    .some((segment) =>
      /^(?:App|router|routes)(?:\.(?:[cm]?[jt]sx?))?$/i.test(segment),
    );
}

function expectOfflineVisualReferenceDocument(source: string) {
  const document = new DOMParser().parseFromString(source, "text/html");
  const scripts = [...document.querySelectorAll("script")];
  const links = [...document.querySelectorAll("link")];
  const resources = [
    ...document.querySelectorAll<HTMLElement>("[src], [href]"),
  ];

  expect(scripts).toHaveLength(1);
  expect(scripts[0].getAttribute("type")).toBe("module");
  expect(scripts[0].getAttribute("src")).toBe(
    "/src/visual-reference/main.tsx",
  );
  expect(links).toHaveLength(0);
  expect(resources).toHaveLength(1);
  resources.forEach((resource) => {
    const value = resource.getAttribute("src") ?? resource.getAttribute("href") ?? "";
    expect(value.startsWith("/")).toBe(true);
    expect(value.startsWith("//")).toBe(false);
    expect(value).not.toMatch(/^[a-z][a-z0-9+.-]*:/i);
  });
}

function expectOfflineVisualReferenceStyles(source: string) {
  expect(source).not.toMatch(/\burl\s*\(/i);
  expect(source).not.toMatch(/@import\b/i);
  expect(source).not.toMatch(/(?:https?:)?\/\//i);
  expect(source).not.toMatch(/[a-z][a-z0-9+.-]*:\/\//i);
}

function expectNoConditionsOrResultsProjectionSource(source: string) {
  expect(source).not.toMatch(
    /<h[1-6]\b[^>]*>\s*(?:Conditions|Results)\s*<\/h[1-6]>/i,
  );
  expect(source).not.toMatch(
    /<(?:section|main|aside)\b[^>]*\baria-label\s*=\s*["'](?:Conditions|Results)["']/i,
  );
  expect(source).not.toMatch(
    /\bdata-reading-section\s*=\s*["'](?:conditions|results)["']/i,
  );
  for (const match of source.matchAll(
    /<section\b[^>]*\bclass(?:Name)?\s*=\s*["']([^"']+)["']/gi,
  )) {
    expect(
      match[1]
        .split(/\s+/)
        .some((token) => forbiddenProjectionClassToken.test(token)),
    ).toBe(false);
  }
}

function expectWrapperWithoutSourceIds(source: string) {
  visualReferenceRenderer.sourceRefs.forEach((sourceRef) =>
    expect(source).not.toContain(sourceRef),
  );
}

function resolveFromTestModule(relativePath: string) {
  return new URL(relativePath, import.meta.url).pathname;
}

function expectAbsoluteViteInputs(
  input: Record<string, string>,
  expected: Record<string, string>,
) {
  expect(input).toEqual(expected);
  Object.values(input).forEach((path) => expect(path.startsWith("/")).toBe(true));
}

async function loadViteInputsInIsolatedProcess(
  configPath: string,
  repositoryRoot: string,
) {
  const nodeChildProcessModule = "node:child_process";
  const { execFileSync } = await import(nodeChildProcessModule);
  const nodeProcess = (
    globalThis as unknown as { process: { execPath: string } }
  ).process;
  const loader = `
    import { pathToFileURL } from "node:url";
    const loaded = await import(pathToFileURL(${JSON.stringify(configPath)}).href);
    const exported = loaded.default;
    const config = typeof exported === "function"
      ? await exported({ command: "build", mode: "production" })
      : exported;
    process.stdout.write(JSON.stringify(config.build.rollupOptions.input));
  `;
  return JSON.parse(
    execFileSync(nodeProcess.execPath, ["--input-type=module", "--eval", loader], {
      cwd: repositoryRoot,
      encoding: "utf8",
    }),
  ) as Record<string, string>;
}

describe("VisualReference", () => {
  it("renders a deterministic non-product reference around the production reading projection", async () => {
    const fetchSpy = vi.fn();
    const sendBeaconSpy = vi.fn();
    const eventSourceSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);
    vi.stubGlobal("EventSource", eventSourceSpy);
    replaceOptionalMethod(
      window.navigator,
      "sendBeacon",
      sendBeaconSpy,
    );
    const storageGetSpy = vi.spyOn(Storage.prototype, "getItem");
    const storageSetSpy = vi.spyOn(Storage.prototype, "setItem");

    const { container, unmount } = render(<VisualReference />);
    await waitFor(() =>
      expect(document.documentElement.dataset.visualReferenceReady).toBe(
        "true",
      ),
    );
    const reference = container.querySelector(
      '[data-visual-reference="SYNTHETIC_VISUAL_REFERENCE_ONLY"]',
    ) as HTMLElement;
    const notice = within(reference).getByText("视觉参考 · 非产品路由", {
      exact: true,
    });
    const reading = within(reference).getByRole("main", {
      name: visualReferenceModule.title,
    });

    expect(reference).toHaveAttribute(
      "data-visual-reference",
      "SYNTHETIC_VISUAL_REFERENCE_ONLY",
    );
    expect(reference).toHaveAttribute("data-product-route", "false");
    expect(notice).toHaveTextContent("视觉参考 · 非产品路由");
    expect(within(reference).getByText("Cognitura", { exact: true }).tagName).toBe(
      "STRONG",
    );
    expect(
      reference.querySelector(".visual-reference__topbar h1"),
    ).toBeNull();
    expect(within(reference).getByRole("navigation", { name: "知识路径" })).toHaveTextContent(
      "数据库系统 / 并发控制 / MVCC",
    );
    expect(reading).toHaveAttribute("data-reading-flow", "continuous-document");
    expect(
      reading.querySelectorAll('[data-primary-visual-projection="true"]'),
    ).toHaveLength(1);
    expect(
      reading.querySelectorAll("[data-reading-section]"),
    ).toHaveLength(8);
    expect(
      reading.querySelectorAll("[data-reading-section='relations'] li"),
    ).toHaveLength(1);
    expect(container.querySelectorAll("aside, [role='complementary']")).toHaveLength(0);
    expectNoDashboardPresentationHooks(reference);
    visualReferenceRenderer.sourceRefs.forEach((sourceRef) =>
      expect(reference).not.toHaveTextContent(sourceRef),
    );
    expectNoConditionsOrResults(reference);
    expectNoConditionsOrResults(reading);

    [
      "visual-dashboard-summary",
      "reading-card-wall-grid",
      "module-metric-row",
      "source-coverage-ring",
      "stage-progress-indicator",
      "reading-glass-surface",
      "visual-gradient-banner",
    ].forEach((forbiddenClass) => {
      const mutated = reference.cloneNode(true) as HTMLElement;
      mutated.classList.add(forbiddenClass);
      expect(() => expectNoDashboardPresentationHooks(mutated)).toThrow();
    });

    const rootAttributeMutation = reference.cloneNode(true) as HTMLElement;
    rootAttributeMutation.setAttribute("data-dashboard", "");
    expect(() => expectNoDashboardPresentationHooks(rootAttributeMutation)).toThrow();

    const descendantAttributeMutation = reference.cloneNode(true) as HTMLElement;
    descendantAttributeMutation
      .querySelector('[data-reading-section="stage-chain"]')
      ?.setAttribute("data-card-wall", "arbitrary-value");
    expect(() =>
      expectNoDashboardPresentationHooks(descendantAttributeMutation),
    ).toThrow();

    const mutatedReference = reference.cloneNode(true) as HTMLElement;
    const forbiddenSection = document.createElement("section");
    forbiddenSection.dataset.readingSection = "conditions";
    forbiddenSection.innerHTML = "<h2>Conditions</h2>";
    mutatedReference.append(forbiddenSection);
    expect(() => expectNoConditionsOrResults(mutatedReference)).toThrow();
    expect(fetchSpy).not.toHaveBeenCalled();
    expect(sendBeaconSpy).not.toHaveBeenCalled();
    expect(eventSourceSpy).not.toHaveBeenCalled();
    expect(storageGetSpy).not.toHaveBeenCalled();
    expect(storageSetSpy).not.toHaveBeenCalled();
    unmount();
    expect(document.documentElement.dataset.visualReferenceReady).toBeUndefined();
  });

  it("uses the exact deterministic canonical-shaped fixture", () => {
    expect(visualReferenceModule).toMatchObject({
      artifactId: "module.mvcc.visual-reference",
      revisionId: "rev.module.mvcc.visual-reference.1",
      primaryParent: "theme.database-concurrency",
      title: "MVCC 一致性读",
      coreQuestions: [
        "一次一致性读，如何从多个记录版本中选出当前事务真正可见的版本？",
      ],
      thesis:
        "一致性读先固定可见性边界，再沿版本链排除不可见版本，最终返回边界内最新的可见记录。",
      facets: [],
      keyTakeaways: [],
      gaps: [],
      qualityAssessment: null,
    });
    expect(visualReferenceModule.primaryCognitiveSpine?.steps).toEqual([
      expect.objectContaining({ order: 1, statement: "创建读取视图，固定当前事务的可见性边界。" }),
      expect.objectContaining({ order: 2, statement: "从当前记录定位版本链入口。" }),
      expect.objectContaining({ order: 3, statement: "比较事务标识与读取视图，排除不可见版本。" }),
      expect.objectContaining({ order: 4, statement: "返回边界内最新的可见记录。" }),
    ]);
    expect(
      visualReferenceModule.knowledgeElements.map(({ artifactId, title, content }) => [
        artifactId,
        title,
        content,
      ]),
    ).toEqual([
      ["element.mvcc.read-view", "读取视图", "固定一次一致性读所使用的事务可见性边界。"],
      ["element.mvcc.record-version", "记录版本", "保存记录在某次事务修改后的历史状态与版本链指针。"],
      ["element.mvcc.visibility", "可见性判断", "按读取视图逐项判断创建事务和删除事务是否可见。"],
      ["element.mvcc.visible-result", "可见结果", "在版本链中选择满足边界的最新记录版本。"],
    ]);
    expect(visualReferenceModule.criticalBoundaries).toEqual([
      expect.objectContaining({
        boundaryId: "boundary.mvcc.visual-reference.1",
        statement: "可见性判断解决读版本选择，但不会消除所有写冲突。",
      }),
    ]);
    expect(visualReferenceModule.relations).toEqual([
      expect.objectContaining({
        relationId: "relation.mvcc.visible-result.depends-read-view",
        type: "DEPENDS_ON",
        sourceRef: "element.mvcc.visible-result",
        targetRef: "element.mvcc.read-view",
        origin: "SOURCE_SYNTHESIZED",
      }),
    ]);
    expect(visualReferenceRenderer.nodes).toHaveLength(4);
    expect(visualReferenceRenderer.nodes.map((node) => node.nodeId)).toEqual([
      "renderer-node.mvcc.read-view",
      "renderer-node.mvcc.record-version",
      "renderer-node.mvcc.visibility",
      "renderer-node.mvcc.visible-result",
    ]);
    expect(visualReferenceRenderer.nodes.map((node) => node.contentPath)).toEqual(
      [0, 1, 2, 3].map((index) => `/knowledgeElements/${index}/title`),
    );
    expect(() =>
      buildVisualReferenceNodes(
        visualReferenceModule.knowledgeElements.slice(0, 3),
      ),
    ).toThrow("VISUAL_REFERENCE_ELEMENT_COUNT_MISMATCH");
    const sparseElements = [...visualReferenceModule.knowledgeElements];
    delete sparseElements[2];
    expect(() => buildVisualReferenceNodes(sparseElements)).toThrow(
      "VISUAL_REFERENCE_ELEMENT_MISSING",
    );
    expect(visualReferenceRenderer.relations).toEqual([
      expect.objectContaining({
        relationId: "renderer-relation.mvcc.visible-result.depends-read-view",
        sourceNodeRef: "renderer-node.mvcc.visible-result",
        targetNodeRef: "renderer-node.mvcc.read-view",
        artifactRelationRef: "relation.mvcc.visible-result.depends-read-view",
      }),
    ]);
  });

  it("defines an independent Vite entry and no online or persistent fixture behavior", () => {
    const parsedDocument = new DOMParser().parseFromString(
      visualReferenceDocument,
      "text/html",
    );
    const entryRoot = parsedDocument.querySelectorAll(
      '#visual-reference-root[data-visual-entry="reference-only"]',
    );
    expect(entryRoot).toHaveLength(1);
    expect(findVisualReferenceRoot(parsedDocument)).toBe(entryRoot[0]);
    const wrongEntryDocument = new DOMParser().parseFromString(
      visualReferenceDocument.replace("reference-only", "product-route"),
      "text/html",
    );
    expect(() => findVisualReferenceRoot(wrongEntryDocument)).toThrow(
      "VISUAL_REFERENCE_ROOT_MISSING",
    );
    expect(visualReferenceDocument).toContain(
      '<script type="module" src="/src/visual-reference/main.tsx"></script>',
    );
    expectOfflineVisualReferenceDocument(visualReferenceDocument);
    expectOfflineVisualReferenceStyles(visualReferenceStyles);
    expect(viteConfigSource).toContain('visualReference:');
    expect(viteConfigSource).toContain(
      'resolve(webRoot, "visual-reference.html")',
    );

    const offlineSources = [
      fixtureSource,
      mainSource,
      visualReferenceSource,
      visualReferenceDocument,
      visualReferenceStyles,
    ];
    expectOfflineFixtureSources(offlineSources);
    expect(() =>
      expectOfflineFixtureSources([
        `${visualReferenceSource}\nfetch("/product-api")`,
      ]),
    ).toThrow();
    expect(() =>
      expectOfflineVisualReferenceDocument(
        `${visualReferenceDocument}\n<link rel="stylesheet" href="//cdn.example/reference.css">`,
      ),
    ).toThrow();
    expect(() =>
      expectOfflineVisualReferenceStyles(
        `${visualReferenceStyles}\n.reference { background: url(//cdn.example/reference.png); }`,
      ),
    ).toThrow();
    expect(() =>
      expectOfflineFixtureSources([
        `${visualReferenceSource}\nimport App from "@workspace/product/App.tsx";`,
      ]),
    ).toThrow();
    expect(() =>
      expectOfflineFixtureSources([
        `${mainSource}\nimport { router } from "#ui/routes.ts";`,
      ]),
    ).toThrow();
    expect(() =>
      expectOfflineFixtureSources([
        `${mainSource}\nconst route = import("~/navigation/router.js");`,
      ]),
    ).toThrow();
    expect(() =>
      expectOfflineFixtureSources([
        'import { ModuleDefaultReading } from "@/modules/module-reading/ModuleDefaultReading";',
      ]),
    ).not.toThrow();
    expect(fixtureSource).not.toContain("SYNTHETIC_VISUAL_REFERENCE_ONLY");
    expect(visualReferenceSource).toContain(
      'data-visual-reference="SYNTHETIC_VISUAL_REFERENCE_ONLY"',
    );
    expectNoConditionsOrResultsProjectionSource(fixtureSource);
    expectNoConditionsOrResultsProjectionSource(visualReferenceSource);
    expect(() =>
      expectNoConditionsOrResultsProjectionSource(
        `${visualReferenceSource}\n<section className="module-results">Results</section>`,
      ),
    ).toThrow();
    expect(() =>
      expectNoConditionsOrResultsProjectionSource(
        `${visualReferenceSource}\n<p>The results remain part of the continuous explanation.</p>`,
      ),
    ).not.toThrow();
    expectWrapperWithoutSourceIds(visualReferenceSource);
    expect(() =>
      expectWrapperWithoutSourceIds(
        `${visualReferenceSource}\n${visualReferenceRenderer.sourceRefs[0]}`,
      ),
    ).toThrow();

    const ordinaryReadingCopy = document.createElement("p");
    ordinaryReadingCopy.textContent =
      "The results remain part of the continuous explanation.";
    expect(() => expectNoConditionsOrResults(ordinaryReadingCopy)).not.toThrow();
  });

  it("resolves both Vite inputs independently of the current working directory", async () => {
    const { loadConfigFromFile } = await import("vite");
    const nodePathModule = "node:path";
    const { isAbsolute, resolve } = await import(nodePathModule);
    const configPath = resolve("vite.config.mjs");
    const webRoot = resolve(".");
    expect(readFileSync(configPath, "utf8")).toContain("fileURLToPath");
    const loaded = await loadConfigFromFile(
      { command: "build", mode: "production" },
      configPath,
    );
    expect(loaded).not.toBeNull();
    const config = loaded!.config;
    const input = config.build?.rollupOptions?.input as Record<string, string>;
    expect(Object.isFrozen(input)).toBe(true);
    expect(input).toEqual({
      app: resolve(webRoot, "index.html"),
      visualReference: resolve(webRoot, "visual-reference.html"),
    });
    Object.values(input).forEach((path) => expect(isAbsolute(path)).toBe(true));

    const configPathFromModule = resolveFromTestModule("../../vite.config.mjs");
    const repositoryRootFromModule = resolveFromTestModule("../../../");
    const webRootFromModule = resolveFromTestModule("../../");
    const isolatedInput = await loadViteInputsInIsolatedProcess(
      configPathFromModule,
      repositoryRootFromModule,
    );
    expectAbsoluteViteInputs(isolatedInput, {
      app: resolve(webRootFromModule, "index.html"),
      visualReference: resolve(webRootFromModule, "visual-reference.html"),
    });

    expect(() =>
      expectAbsoluteViteInputs(
        { app: "./index.html", visualReference: "./visual-reference.html" },
        {
          app: resolve(webRootFromModule, "index.html"),
          visualReference: resolve(
            webRootFromModule,
            "visual-reference.html",
          ),
        },
      ),
    ).toThrow();
    expect(visualReferenceDocument).toMatch(/<html\s+lang="zh-CN">/);
  });

  it("keeps the reference canvas responsive and consumes only semantic tokens", () => {
    [
      "--color-canvas",
      "--text-primary",
      "--text-muted",
      "--border-subtle",
      "--application-max-width",
    ].forEach((token) => expect(visualReferenceStyles).toContain(token));
    expect(visualReferenceStyles).toMatch(/@media\s*\(max-width:/);
    expect(visualReferenceStyles).not.toMatch(/#[0-9a-f]{3,8}\b/i);
    expect(visualReferenceStyles).not.toMatch(/\b(?:rgb|hsl)a?\(/i);
    expect(visualReferenceStyles).not.toMatch(/gradient\s*\(/i);
    expectSmallScreenBreadcrumbPaddingContract(visualReferenceStyles);
    expectBreadcrumbBorderBox(visualReferenceStyles);
    expect(() =>
      expectBreadcrumbBorderBox(
        `${visualReferenceStyles}\n.visual-reference__path { box-sizing: content-box; }`,
      ),
    ).toThrow();
  });
});
