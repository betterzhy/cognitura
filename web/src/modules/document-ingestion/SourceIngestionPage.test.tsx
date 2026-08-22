import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { SourceIngestionPage } from "./SourceIngestionPage";

const blockSetDigest = "a".repeat(64);
const omissionsDigest = "b".repeat(64);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const uploadResponse = {
  sourceDocumentId: "source-a",
  sourceIngestionDisplayStatus: "VALIDATING",
  contentSha256: "c".repeat(64),
  receivedAt: "2026-08-22T04:00:00Z",
};

const processingResponse = {
  sourceDocumentId: "source-a",
  sourceProcessingRevisionId: "revision-a",
  sourceProcessingRevisionStatus: "PARSING",
  sourceIngestionDisplayStatus: "PARSING",
  pollLocation: "/api/v1/source-documents/source-a/processing-revisions/revision-a",
  reused: false,
};

function revisionStatus(parseCompleteness: "COMPLETE" | "PARTIAL") {
  return {
    sourceDocumentId: "source-a",
    sourceProcessingRevisionId: "revision-a",
    parserProfileVersion: "docx-v1",
    sourceProcessingRevisionStatus: "PREVIEW_READY",
    sourceIngestionDisplayStatus: "PREVIEW_READY",
    parseCompleteness,
    omissions:
      parseCompleteness === "PARTIAL"
        ? [
            {
              sourcePart: "word/document.xml",
              sourceElementIndex: 3,
              errorCode: "UNSUPPORTED_SAFE_OOXML",
              userVisibleDescription: "一个来源结构暂时无法投影。",
            },
          ]
        : [],
    publishedBlockSetDigest: blockSetDigest,
    omissionsDigest,
    partialAcceptanceStatus:
      parseCompleteness === "PARTIAL" ? "PENDING" : "NOT_APPLICABLE",
    failureCode: null,
    failureDetail: null,
    startedAt: "2026-08-22T04:00:01Z",
    completedAt: "2026-08-22T04:00:02Z",
  };
}

function preview(parseCompleteness: "COMPLETE" | "PARTIAL") {
  return {
    sourceDocumentId: "source-a",
    sourceProcessingRevisionId: "revision-a",
    originalFileName: "Redis 中间件.docx",
    parseCompleteness,
    publishedBlockSetDigest: blockSetDigest,
    omissionsDigest,
    incomplete: parseCompleteness === "PARTIAL",
    partialWarning:
      parseCompleteness === "PARTIAL"
        ? "This preview is incomplete. Review all listed omissions before acceptance."
        : null,
    omissions: revisionStatus(parseCompleteness).omissions,
    items: [
      {
        documentBlockId: "block-a",
        documentBlockRef: `dbr:${"d".repeat(64)}`,
        blockType: "PARAGRAPH",
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
        contentHash: "e".repeat(64),
        payload: { text: "AOF 通过追加命令恢复数据。", styleName: "Normal" },
        affectedByOmission: parseCompleteness === "PARTIAL",
      },
    ],
    nextCursor: null,
  };
}

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

describe("SourceIngestionPage", () => {
  it("uploads the exact multipart command and follows the formal poll location to preview", async () => {
    const fetchMock = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(json(uploadResponse, 201))
      .mockResolvedValueOnce(json(processingResponse, 202))
      .mockResolvedValueOnce(json(revisionStatus("COMPLETE")))
      .mockResolvedValueOnce(json(preview("COMPLETE")));
    vi.stubGlobal("fetch", fetchMock);
    const user = userEvent.setup();
    render(<SourceIngestionPage workspaceId="workspace-a" parserProfileVersion="docx-v1" />);

    const file = new File(["docx-bytes"], "Redis 中间件.docx", {
      type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    });
    await user.upload(screen.getByLabelText("选择 DOCX 文件"), file);
    await user.type(screen.getByLabelText("幂等键"), "upload-key-a");
    await user.click(screen.getByRole("button", { name: "上传来源" }));

    expect(await screen.findByText("来源已登记，等待处理")).toBeVisible();
    await user.click(screen.getByRole("button", { name: "开始处理" }));
    expect(await screen.findByText("AOF 通过追加命令恢复数据。")).toBeVisible();
    expect(screen.getByText("预览已就绪")).toBeVisible();

    const uploadCall = fetchMock.mock.calls[0];
    expect(uploadCall[0]).toBe("/api/v1/workspaces/workspace-a/source-documents");
    const form = uploadCall[1]?.body as FormData;
    expect(form.get("file")).toBe(file);
    const command = JSON.parse(await (form.get("command") as Blob).text());
    expect(Object.keys(command).sort()).toEqual([
      "contentSha256",
      "declaredByteLength",
      "declaredMediaType",
      "idempotencyKey",
      "originalFileName",
    ]);
    expect(command).toMatchObject({
      idempotencyKey: "upload-key-a",
      originalFileName: "Redis 中间件.docx",
      declaredByteLength: file.size,
      declaredMediaType: file.type,
    });
    expect(command.contentSha256).toMatch(/^[0-9a-f]{64}$/);
    expect(fetchMock.mock.calls[2][0]).toBe(processingResponse.pollLocation);
  });

  it("confirms only the original partial preview tuple and preserves it on conflict", async () => {
    const fetchMock = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(json(uploadResponse, 201))
      .mockResolvedValueOnce(json(processingResponse, 202))
      .mockResolvedValueOnce(json(revisionStatus("PARTIAL")))
      .mockResolvedValueOnce(json(preview("PARTIAL")))
      .mockResolvedValueOnce(
        json(
          {
            errorCode: "PARTIAL_ACCEPTANCE_CONFLICT",
            message: "The partial acceptance command conflicts with the exact revision.",
            retryable: false,
            sourceDocumentId: "source-a",
            sourceProcessingRevisionId: "revision-a",
          },
          409,
        ),
      );
    vi.stubGlobal("fetch", fetchMock);
    const user = userEvent.setup();
    render(<SourceIngestionPage workspaceId="workspace-a" parserProfileVersion="docx-v1" />);

    await user.upload(
      screen.getByLabelText("选择 DOCX 文件"),
      new File(["docx-bytes"], "Redis 中间件.docx", {
        type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      }),
    );
    await user.type(screen.getByLabelText("幂等键"), "upload-key-a");
    await user.click(screen.getByRole("button", { name: "上传来源" }));
    await user.click(await screen.findByRole("button", { name: "开始处理" }));
    await screen.findByRole("status", { name: "来源预览不完整" });
    await user.click(screen.getByRole("button", { name: "确认使用当前不完整来源" }));

    expect(await screen.findByText("当前预览已变化，请重新核验后再确认。")).toBeVisible();
    const acceptance = fetchMock.mock.calls[4];
    expect(acceptance[0]).toBe(
      "/api/v1/source-documents/source-a/processing-revisions/revision-a/partial-acceptance",
    );
    expect(JSON.parse(acceptance[1]?.body as string)).toMatchObject({
      blockSetDigest,
      omissionsDigest,
      decision: "ACCEPT_PARTIAL",
    });
    expect(screen.getByTestId("partial-tuple")).toHaveAttribute(
      "data-block-set-digest",
      blockSetDigest,
    );
    expect(screen.getByTestId("partial-tuple")).toHaveAttribute(
      "data-omissions-digest",
      omissionsDigest,
    );
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(5));
  });
});
