import { cleanup, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { getPreview, SourceApiError, type SourcePreviewPage } from "./api";
import { SourcePreview } from "./SourcePreview";

const digestA = "a".repeat(64);
const digestB = "b".repeat(64);

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

function json(body: unknown) {
  return new Response(JSON.stringify(body), { status: 200, headers: { "Content-Type": "application/json" } });
}

function partialPreview(): SourcePreviewPage {
  return {
    sourceDocumentId: "source-a",
    sourceProcessingRevisionId: "revision-a",
    originalFileName: "Redis 中间件.docx",
    parseCompleteness: "PARTIAL",
    publishedBlockSetDigest: digestA,
    omissionsDigest: digestB,
    incomplete: true,
    partialWarning:
      "This preview is incomplete. Review all listed omissions before acceptance.",
    omissions: [
      {
        sourcePart: "word/document.xml",
        sourceElementIndex: 2,
        errorCode: "UNSUPPORTED_SAFE_OOXML",
        userVisibleDescription: "一个安全来源结构暂时无法投影。",
      },
    ],
    items: [
      {
        documentBlockId: "block-heading",
        documentBlockRef: `dbr:${"1".repeat(64)}`,
        blockType: "HEADING",
        sourceOrder: 0,
        sectionPath: [],
        pageNumber: null,
        pageEvidence: null,
        sourceAnchor: {
          anchorKind: "FLOW",
          parentBlockId: null,
          textOffset: null,
          childOrdinal: null,
          rowIndex: null,
          columnIndex: null,
        },
        contentHash: "c".repeat(64),
        payload: { text: "Redis 持久化与恢复", level: 1, styleName: "Heading 1" },
        affectedByOmission: false,
      },
      {
        documentBlockId: "block-paragraph",
        documentBlockRef: `dbr:${"2".repeat(64)}`,
        blockType: "PARAGRAPH",
        sourceOrder: 1,
        sectionPath: ["Redis 持久化与恢复"],
        pageNumber: null,
        pageEvidence: null,
        sourceAnchor: {
          anchorKind: "FLOW",
          parentBlockId: null,
          textOffset: null,
          childOrdinal: null,
          rowIndex: null,
          columnIndex: null,
        },
        contentHash: "d".repeat(64),
        payload: { text: "AOF 通过追加命令恢复数据。", styleName: "Normal" },
        affectedByOmission: true,
      },
      {
        documentBlockId: "block-list",
        documentBlockRef: `dbr:${"3".repeat(64)}`,
        blockType: "LIST",
        sourceOrder: 2,
        sectionPath: ["Redis 持久化与恢复"],
        pageNumber: null,
        pageEvidence: null,
        sourceAnchor: {
          anchorKind: "FLOW",
          parentBlockId: null,
          textOffset: null,
          childOrdinal: null,
          rowIndex: null,
          columnIndex: null,
        },
        contentHash: "e".repeat(64),
        payload: {
          listInstanceId: "list-a",
          itemLevel: 0,
          itemOrdinal: 0,
          markerText: "1.",
          text: "先写入缓冲区，再同步到磁盘。",
        },
        affectedByOmission: false,
      },
    ],
    nextCursor: "cursor-next",
  };
}

describe("SourcePreview", () => {
  it("renders typed blocks in API order and makes partial evidence unmistakable", () => {
    const preview = partialPreview();
    const { container } = render(
      <SourcePreview preview={preview} loadingMore={false} onLoadMore={vi.fn()} />,
    );

    expect(screen.getByRole("heading", { name: "Redis 中间件.docx" })).toBeVisible();
    expect(screen.getByRole("status", { name: "来源预览不完整" })).toHaveTextContent(
      "1 处内容未能安全投影",
    );
    const blocks = Array.from(container.querySelectorAll("[data-source-order]"));
    expect(blocks.map((block) => block.getAttribute("data-source-order"))).toEqual([
      "0",
      "1",
      "2",
    ]);
    expect(blocks[0]).toHaveTextContent("Redis 持久化与恢复");
    expect(blocks[1]).toHaveTextContent("AOF 通过追加命令恢复数据。");
    expect(blocks[1]).toHaveAttribute("data-affected-by-omission", "true");
    expect(within(blocks[2] as HTMLElement).getByText("1.")).toBeVisible();
    expect(screen.getByText("word/document.xml · #2")).toBeVisible();
    expect(screen.queryByText("block-paragraph")).toBeNull();
    expect(screen.queryByText(digestA)).toBeNull();
    expect(screen.getByText("处理修订 revision-a")).toBeVisible();
    expect(screen.getByText("来源顺序 0")).toBeVisible();
    expect(screen.getAllByText("页码未提供")).toHaveLength(3);
  });

  it("requests the next exact cursor without reordering the current page", async () => {
    const user = userEvent.setup();
    const onLoadMore = vi.fn();
    render(
      <SourcePreview
        preview={partialPreview()}
        loadingMore={false}
        onLoadMore={onLoadMore}
      />,
    );

    await user.click(screen.getByRole("button", { name: "继续加载来源内容" }));
    expect(onLoadMore).toHaveBeenCalledOnce();
  });

  it.each([
    ["unknown block type", { ...partialPreview(), items: [{ ...partialPreview().items[0], blockType: "UNKNOWN" }] }],
    ["malformed table payload", { ...partialPreview(), items: [{ ...partialPreview().items[0], blockType: "TABLE", payload: { rows: null } }] }],
  ])("rejects %s instead of silently omitting source content", async (_name, response) => {
    vi.stubGlobal("fetch", vi.fn<typeof fetch>().mockResolvedValue(json(response)));
    await expect(getPreview("source-a", "revision-a")).rejects.toEqual(
      expect.objectContaining<Partial<SourceApiError>>({ code: "MALFORMED_RESPONSE" }),
    );
  });
});
