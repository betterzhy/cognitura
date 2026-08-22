import type { ProcessingResult, RevisionStatus, UploadResult } from "./api";

interface ProcessingStatusProps {
  upload: UploadResult | null;
  processing: ProcessingResult | null;
  revision: RevisionStatus | null;
  busy: boolean;
  onStart: () => void;
  onRefresh: () => void;
}

function label(revision: RevisionStatus | null) {
  if (!revision) return "来源已登记，等待处理";
  switch (revision.sourceIngestionDisplayStatus) {
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
  onRefresh,
}: ProcessingStatusProps) {
  if (!upload) return null;
  const ready = revision?.sourceIngestionDisplayStatus === "PREVIEW_READY";
  const running = processing && !ready;
  return (
    <section className="cka-process" aria-live="polite">
      <div className="cka-process__header">
        <div>
          <span className={`cka-status-dot ${ready ? "is-ready" : ""}`} aria-hidden="true" />
          <strong>{label(revision)}</strong>
        </div>
        <span className="cka-process__badge">{ready ? "可核验" : "已安全登记"}</span>
      </div>
      <ol className="cka-process__steps" aria-label="来源处理进度">
        <li className="is-complete"><span>1</span>登记来源</li>
        <li className={processing ? "is-complete" : "is-current"}><span>2</span>解析结构</li>
        <li className={ready ? "is-complete" : processing ? "is-current" : ""}><span>3</span>核验预览</li>
      </ol>
      {!processing ? (
        <button className="cka-button cka-button--primary" onClick={onStart} disabled={busy}>
          {busy ? "正在启动…" : "开始处理"}
        </button>
      ) : running ? (
        <button className="cka-button cka-button--secondary" onClick={onRefresh} disabled={busy}>
          {busy ? "正在刷新…" : "刷新处理状态"}
        </button>
      ) : null}
    </section>
  );
}
