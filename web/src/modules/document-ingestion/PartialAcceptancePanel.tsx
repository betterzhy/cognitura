import type { PartialAcceptanceResult, SourcePreviewPage } from "./api";

interface PartialAcceptancePanelProps {
  preview: SourcePreviewPage;
  result: PartialAcceptanceResult | null;
  busy: boolean;
  error: string | null;
  onAccept: () => void;
}

export function PartialAcceptancePanel({
  preview,
  result,
  busy,
  error,
  onAccept,
}: PartialAcceptancePanelProps) {
  if (!preview.incomplete) return null;
  return (
    <aside
      className="cka-acceptance"
      data-testid="partial-tuple"
      data-block-set-digest={preview.publishedBlockSetDigest}
      data-omissions-digest={preview.omissionsDigest}
    >
      <div>
        <span className="cka-acceptance__label">需要你的判断</span>
        <h3>{result ? "已确认使用当前来源" : "是否接受这份不完整来源？"}</h3>
        <p>
          {result
            ? "确认结果已经固定，后续认知构建只会使用这次核验过的内容。"
            : "确认只针对当前预览与上方列出的缺失项；内容一旦变化，需要重新核验。"}
        </p>
      </div>
      {error ? <p className="cka-inline-error">{error}</p> : null}
      {!result ? (
        <button className="cka-button cka-button--warning" onClick={onAccept} disabled={busy}>
          {busy ? "正在确认…" : "确认使用当前不完整来源"}
        </button>
      ) : (
        <span className="cka-acceptance__done">✓ 已记录</span>
      )}
    </aside>
  );
}
