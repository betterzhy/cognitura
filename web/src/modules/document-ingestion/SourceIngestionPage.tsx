import { useState } from "react";

import {
  acceptPartial,
  getPreview,
  getRevisionStatus,
  SourceApiError,
  startProcessing,
  uploadSource,
  type PartialAcceptanceResult,
  type ProcessingResult,
  type RevisionStatus,
  type SourcePreviewPage,
  type UploadResult,
} from "./api";
import { PartialAcceptancePanel } from "./PartialAcceptancePanel";
import { ProcessingStatus } from "./ProcessingStatus";
import { SourcePreview } from "./SourcePreview";
import { SourceUploadPanel } from "./SourceUploadPanel";
import "./source-ingestion.css";

export interface SourceIngestionPageProps {
  workspaceId: string;
  parserProfileVersion: string;
}

function safeMessage(error: unknown) {
  if (error instanceof SourceApiError) {
    if (error.code === "PARTIAL_ACCEPTANCE_CONFLICT") {
      return "当前预览已变化，请重新核验后再确认。";
    }
    if (error.code === "RESOURCE_NOT_FOUND") return "当前来源不可用或已经移除。";
    if (error.code === "IDEMPOTENCY_CONFLICT") return "这个幂等键已用于另一份内容。";
    return error.retryable ? "请求暂时未完成，请稍后重试。" : "当前操作未能完成，请核对输入。";
  }
  return "当前操作未能完成，请稍后重试。";
}

export function SourceIngestionPage({ workspaceId, parserProfileVersion }: SourceIngestionPageProps) {
  const [upload, setUpload] = useState<UploadResult | null>(null);
  const [processing, setProcessing] = useState<ProcessingResult | null>(null);
  const [revision, setRevision] = useState<RevisionStatus | null>(null);
  const [preview, setPreview] = useState<SourcePreviewPage | null>(null);
  const [acceptance, setAcceptance] = useState<PartialAcceptanceResult | null>(null);
  const [busy, setBusy] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [acceptanceError, setAcceptanceError] = useState<string | null>(null);

  async function uploadFile(file: File, idempotencyKey: string) {
    setBusy(true);
    setError(null);
    try {
      setUpload(await uploadSource(workspaceId, file, idempotencyKey));
      setProcessing(null);
      setRevision(null);
      setPreview(null);
      setAcceptance(null);
    } catch (failure) {
      setError(safeMessage(failure));
    } finally {
      setBusy(false);
    }
  }

  async function refreshStatus(result = processing) {
    if (!result) return;
    setBusy(true);
    setError(null);
    try {
      const nextRevision = await getRevisionStatus(result.pollLocation);
      setRevision(nextRevision);
      if (nextRevision.sourceIngestionDisplayStatus === "PREVIEW_READY") {
        setPreview(await getPreview(result.sourceDocumentId, result.sourceProcessingRevisionId));
      }
    } catch (failure) {
      setError(safeMessage(failure));
    } finally {
      setBusy(false);
    }
  }

  async function beginProcessing() {
    if (!upload) return;
    setBusy(true);
    setError(null);
    try {
      const result = await startProcessing(upload.sourceDocumentId, parserProfileVersion);
      setProcessing(result);
      const nextRevision = await getRevisionStatus(result.pollLocation);
      setRevision(nextRevision);
      if (nextRevision.sourceIngestionDisplayStatus === "PREVIEW_READY") {
        setPreview(await getPreview(result.sourceDocumentId, result.sourceProcessingRevisionId));
      }
    } catch (failure) {
      setError(safeMessage(failure));
    } finally {
      setBusy(false);
    }
  }

  async function loadMore() {
    if (!preview?.nextCursor) return;
    setLoadingMore(true);
    try {
      const page = await getPreview(
        preview.sourceDocumentId,
        preview.sourceProcessingRevisionId,
        preview.nextCursor,
      );
      setPreview({ ...page, items: [...preview.items, ...page.items] });
    } catch (failure) {
      setError(safeMessage(failure));
    } finally {
      setLoadingMore(false);
    }
  }

  async function confirmPartial() {
    if (!preview) return;
    setBusy(true);
    setAcceptanceError(null);
    try {
      setAcceptance(await acceptPartial(
        preview.sourceDocumentId,
        preview.sourceProcessingRevisionId,
        preview.publishedBlockSetDigest,
        preview.omissionsDigest,
        `accept:${preview.sourceProcessingRevisionId}:${preview.publishedBlockSetDigest.slice(0, 12)}`,
      ));
    } catch (failure) {
      setAcceptanceError(safeMessage(failure));
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="cka-ingestion">
      <header className="cka-ingestion__masthead">
        <div>
          <span className="cka-ingestion__brand">COGNITURA</span>
          <h1>构建一份可追溯的认知来源</h1>
          <p>先核验来源，再进入知识结构构建。每一步都保留原始顺序与边界。</p>
        </div>
        <div className="cka-ingestion__stage">来源摄取 · 第 1 步</div>
      </header>

      <div className="cka-ingestion__workspace">
        <aside className="cka-ingestion__rail">
          <SourceUploadPanel busy={busy} onUpload={uploadFile} />
          <ProcessingStatus
            upload={upload}
            processing={processing}
            revision={revision}
            busy={busy}
            onStart={beginProcessing}
            onRetry={beginProcessing}
            onRefresh={() => refreshStatus()}
          />
          {error ? <p className="cka-page-error" role="alert">{error}</p> : null}
        </aside>

        <section className="cka-ingestion__content" aria-label="来源核验区">
          {preview ? (
            <>
              <SourcePreview preview={preview} loadingMore={loadingMore} onLoadMore={loadMore} />
              <PartialAcceptancePanel
                preview={preview}
                status={revision?.partialAcceptanceStatus ?? null}
                result={acceptance}
                busy={busy}
                error={acceptanceError}
                onAccept={confirmPartial}
              />
            </>
          ) : (
            <div className="cka-ingestion__empty">
              <span aria-hidden="true">01</span>
              <h2>来源预览将在这里展开</h2>
              <p>选择一份 DOCX 并开始处理。页面会按原始顺序连续呈现标题、段落、列表、表格与图像证据。</p>
              <div className="cka-ingestion__empty-lines" aria-hidden="true"><i /><i /><i /></div>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
