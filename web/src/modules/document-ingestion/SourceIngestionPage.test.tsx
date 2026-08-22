import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { SourceIngestionPage } from "./SourceIngestionPage";
import { ProcessingStatus } from "./ProcessingStatus";

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

async function uploadAndStart(user: ReturnType<typeof userEvent.setup>) {
  await user.upload(
    screen.getByLabelText("选择 DOCX 文件"),
    new File(["docx-bytes"], "Redis 中间件.docx", {
      type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    }),
  );
  await user.type(screen.getByLabelText("幂等键"), "upload-key-a");
  await user.click(screen.getByRole("button", { name: "上传来源" }));
  await user.click(await screen.findByRole("button", { name: "检查并开始处理" }));
}

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

    expect(await screen.findByText("来源正在校验")).toBeVisible();
    await user.click(screen.getByRole("button", { name: "检查并开始处理" }));
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
    await user.click(await screen.findByRole("button", { name: "检查并开始处理" }));
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

  it("renders a reused accepted partial revision as read-only without another POST", async () => {
    const acceptedRevision = { ...revisionStatus("PARTIAL"), partialAcceptanceStatus: "ACCEPTED" };
    const fetchMock = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(json(uploadResponse, 201))
      .mockResolvedValueOnce(json(processingResponse, 200))
      .mockResolvedValueOnce(json(acceptedRevision))
      .mockResolvedValueOnce(json(preview("PARTIAL")));
    vi.stubGlobal("fetch", fetchMock);
    const user = userEvent.setup();
    render(<SourceIngestionPage workspaceId="workspace-a" parserProfileVersion="docx-v1" />);

    await uploadAndStart(user);
    expect(await screen.findByText("已确认使用当前来源")).toBeVisible();
    expect(screen.getByText("✓ 已记录")).toBeVisible();
    expect(screen.queryByRole("button", { name: "确认使用当前不完整来源" })).toBeNull();
    expect(fetchMock).toHaveBeenCalledTimes(4);
  });

  it("projects a successful partial acceptance as a read-only result", async () => {
    const fetchMock = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(json(uploadResponse, 201))
      .mockResolvedValueOnce(json(processingResponse, 202))
      .mockResolvedValueOnce(json(revisionStatus("PARTIAL")))
      .mockResolvedValueOnce(json(preview("PARTIAL")))
      .mockResolvedValueOnce(json({
        sourceDocumentId: "source-a", sourceProcessingRevisionId: "revision-a",
        partialAcceptanceStatus: "ACCEPTED", partialAcceptedAt: "2026-08-22T04:00:03Z",
        acceptedBy: "actor-a", consumptionEligible: true, idempotentReplay: false,
      }));
    vi.stubGlobal("fetch", fetchMock);
    const user = userEvent.setup();
    render(<SourceIngestionPage workspaceId="workspace-a" parserProfileVersion="docx-v1" />);

    await uploadAndStart(user);
    await user.click(await screen.findByRole("button", { name: "确认使用当前不完整来源" }));
    expect(await screen.findByText("已确认使用当前来源")).toBeVisible();
    expect(screen.queryByRole("button", { name: "确认使用当前不完整来源" })).toBeNull();
    expect(fetchMock).toHaveBeenCalledTimes(5);
  });

  it("keeps a validating source retryable when processing is not accepted yet", async () => {
    const fetchMock = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(json(uploadResponse, 201))
      .mockResolvedValueOnce(json({ errorCode: "SOURCE_NOT_ACCEPTED_YET", message: "not ready", retryable: true, sourceDocumentId: null, sourceProcessingRevisionId: null }, 503));
    vi.stubGlobal("fetch", fetchMock);
    const user = userEvent.setup();
    render(<SourceIngestionPage workspaceId="workspace-a" parserProfileVersion="docx-v1" />);

    await uploadAndStart(user);
    expect(await screen.findByText("请求暂时未完成，请稍后重试。")).toBeVisible();
    expect(screen.getByRole("button", { name: "检查并开始处理" })).toBeVisible();
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});

describe("ProcessingStatus", () => {
  it("keeps validating, parsing, retryable and terminal actions distinct", () => {
    const actions = { onStart: vi.fn(), onRetry: vi.fn(), onRefresh: vi.fn() };
    const { rerender } = render(
      <ProcessingStatus upload={uploadResponse} processing={null} revision={null} busy={false} {...actions} />,
    );
    expect(screen.getByText("来源正在校验")).toBeVisible();
    expect(screen.getByRole("button", { name: "检查并开始处理" })).toBeVisible();

    const parsing = { ...revisionStatus("COMPLETE"), sourceProcessingRevisionStatus: "PARSING", sourceIngestionDisplayStatus: "PARSING", parseCompleteness: null, publishedBlockSetDigest: null, omissionsDigest: null, partialAcceptanceStatus: null, completedAt: null };
    rerender(<ProcessingStatus upload={uploadResponse} processing={processingResponse} revision={parsing} busy={false} {...actions} />);
    expect(screen.getByRole("button", { name: "刷新处理状态" })).toBeVisible();

    const retryable = { ...parsing, sourceProcessingRevisionStatus: "FAILED_RETRYABLE", sourceIngestionDisplayStatus: "RETRYABLE_FAILURE", failureCode: "TRANSIENT" };
    rerender(<ProcessingStatus upload={uploadResponse} processing={processingResponse} revision={retryable} busy={false} {...actions} />);
    expect(screen.getByRole("button", { name: "重新开始处理" })).toBeVisible();
    expect(screen.queryByRole("button", { name: "刷新处理状态" })).toBeNull();

    const terminal = { ...parsing, sourceProcessingRevisionStatus: "FAILED_TERMINAL", sourceIngestionDisplayStatus: "TERMINAL_FAILURE", failureCode: "UNSUPPORTED" };
    rerender(<ProcessingStatus upload={uploadResponse} processing={processingResponse} revision={terminal} busy={false} {...actions} />);
    expect(screen.getByText("当前来源无法继续处理")).toBeVisible();
    expect(screen.queryByRole("button")).toBeNull();

    const terminalUpload = {
      ...uploadResponse,
      sourceIngestionDisplayStatus: "TERMINAL_FAILURE" as const,
    };
    rerender(<ProcessingStatus upload={terminalUpload} processing={null} revision={null} busy={false} {...actions} />);
    expect(screen.getByText("当前来源无法继续处理")).toBeVisible();
    expect(screen.queryByRole("button")).toBeNull();
  });
});
