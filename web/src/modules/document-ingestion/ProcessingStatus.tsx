import type { ProcessingResult, RevisionStatus, UploadResult } from "./api";

interface ProcessingStatusProps {
  upload: UploadResult | null;
  processing: ProcessingResult | null;
  revision: RevisionStatus | null;
  busy: boolean;
  onStart: () => void;
  onRetry: () => void;
  onRefresh: () => void;
}

function label(upload: UploadResult, revision: RevisionStatus | null) {
  const status = revision?.sourceIngestionDisplayStatus ?? upload.sourceIngestionDisplayStatus;
  switch (status) {
    case "VALIDATING":
      return "来源正在校验";
    case "PREVIEW_READY":
      return "预览已就绪";
    case "RETRYABLE_FAILURE":
      return "处理暂时中断，可以重试";
    case "TERMINAL_FAILURE":
      return "当前来源无法继续处理";
    default:
      return "正在保留来源结构";
  }
}

export function ProcessingStatus({
  upload,
  processing,
  revision,
  busy,
  onStart,
  onRetry,
  onRefresh,
}: ProcessingStatusProps) {
  if (!upload) return null;
  const status = revision?.sourceIngestionDisplayStatus ?? upload.sourceIngestionDisplayStatus;
  const ready = status === "PREVIEW_READY";
  const retryable = status === "RETRYABLE_FAILURE";
  const terminal = status === "TERMINAL_FAILURE";
  const running = processing && !ready && !retryable && !terminal;
  return (
    <section className="cka-process" aria-live="polite">
      <div className="cka-process__header">
        <div>
          <span className={`cka-status-dot ${ready ? "is-ready" : ""}`} aria-hidden="true" />
          <strong>{label(upload, revision)}</strong>
        </div>
        <span className="cka-process__badge">{ready ? "可核验" : "已安全登记"}</span>
      </div>
      <ol className="cka-process__steps" aria-label="来源处理进度">
        <li className="is-complete"><span>1</span>登记来源</li>
        <li className={processing ? "is-complete" : "is-current"}><span>2</span>解析结构</li>
        <li className={ready ? "is-complete" : processing ? "is-current" : ""}><span>3</span>核验预览</li>
      </ol>
      {terminal ? null : !processing ? (
        <button className="cka-button cka-button--primary" onClick={onStart} disabled={busy}>
          {busy ? "正在检查…" : status === "VALIDATING" ? "检查并开始处理" : "开始处理"}
        </button>
      ) : retryable ? (
        <button className="cka-button cka-button--primary" onClick={onRetry} disabled={busy}>
          {busy ? "正在重试…" : "重新开始处理"}
        </button>
      ) : running ? (
        <button className="cka-button cka-button--secondary" onClick={onRefresh} disabled={busy}>
          {busy ? "正在刷新…" : "刷新处理状态"}
        </button>
      ) : null}
    </section>
  );
}
