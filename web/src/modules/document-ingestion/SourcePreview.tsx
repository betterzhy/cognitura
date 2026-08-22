import { SourceApiError, type SourcePreviewItem, type SourcePreviewPage } from "./api";

interface SourcePreviewProps {
  preview: SourcePreviewPage;
  loadingMore: boolean;
  onLoadMore: () => void;
}

function renderPayload(item: SourcePreviewItem) {
  const payload = item.payload as Record<string, unknown>;
  switch (item.blockType) {
    case "HEADING": {
      const level = Math.min(4, Math.max(2, Number(payload.level) + 1));
      const Heading = `h${level}` as "h2";
      return <Heading>{String(payload.text)}</Heading>;
    }
    case "PARAGRAPH":
      return <p>{String(payload.text)}</p>;
    case "LIST":
      return (
        <div className="cka-source-list-item">
          <span>{payload.markerText ? String(payload.markerText) : "•"}</span>
          <p>{String(payload.text)}</p>
        </div>
      );
    case "TABLE": {
      const rows = payload.rows as Array<{ rowIndex: number; cells: Array<{ columnIndex: number; rowSpan: number; columnSpan: number; text: string }> }>;
      return (
        <div className="cka-source-table-wrap">
          <table><tbody>{rows.map((row) => (
            <tr key={row.rowIndex}>{row.cells.map((cell) => (
              <td key={cell.columnIndex} rowSpan={cell.rowSpan} colSpan={cell.columnSpan}>{cell.text}</td>
            ))}</tr>
          ))}</tbody></table>
        </div>
      );
    }
    case "IMAGE":
      return (
        <figure className="cka-source-image">
          <div aria-hidden="true">图像来源</div>
          <figcaption>
            {payload.relationshipMode === "EXTERNAL"
              ? "外部图像关系已隔离，未访问其目标。"
              : `${String(payload.mediaType ?? "内部媒体")} · ${String(payload.byteLength ?? "—")} bytes`}
          </figcaption>
        </figure>
      );
    default:
      throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  }
}

export function SourcePreview({ preview, loadingMore, onLoadMore }: SourcePreviewProps) {
  return (
    <article className="cka-preview" aria-labelledby="source-preview-title">
      <header className="cka-preview__header">
        <div>
          <span className="cka-preview__kicker">来源连续预览</span>
          <h2 id="source-preview-title">{preview.originalFileName}</h2>
          <p className="cka-preview__revision">处理修订 {preview.sourceProcessingRevisionId}</p>
        </div>
        <span className={`cka-preview__completeness ${preview.incomplete ? "is-partial" : ""}`}>
          {preview.incomplete ? "部分可用" : "结构完整"}
        </span>
      </header>

      {preview.incomplete ? (
        <section className="cka-partial-warning" role="status" aria-label="来源预览不完整">
          <strong>这份预览仍有边界需要确认</strong>
          <p>{preview.omissions.length} 处内容未能安全投影，其余内容仍按来源顺序展示。</p>
          <ul>{preview.omissions.map((omission) => (
            <li key={`${omission.sourcePart}:${omission.sourceElementIndex}`}>
              <span>{omission.sourcePart} · #{omission.sourceElementIndex}</span>
              {omission.userVisibleDescription}
            </li>
          ))}</ul>
        </section>
      ) : null}

      <div className="cka-preview__reading-surface">
        {preview.items.map((item) => (
          <section
            className={`cka-source-block cka-source-block--${item.blockType.toLowerCase()} ${item.affectedByOmission ? "is-affected" : ""}`}
            key={item.documentBlockRef}
            data-source-order={item.sourceOrder}
            data-affected-by-omission={String(item.affectedByOmission)}
          >
            <div className="cka-source-block__trace">
              <span>{item.blockType}</span>
              <span>来源顺序 {item.sourceOrder}</span>
              <span>{item.sectionPath.length ? item.sectionPath.join(" / ") : "文档根级"}</span>
              <span>{item.pageNumber === null ? "页码未提供" : `第 ${item.pageNumber} 页`}</span>
            </div>
            {item.affectedByOmission ? <span className="cka-source-block__flag">受缺失内容影响</span> : null}
            {renderPayload(item)}
          </section>
        ))}
      </div>

      {preview.nextCursor ? (
        <button className="cka-button cka-button--secondary cka-preview__more" onClick={onLoadMore} disabled={loadingMore}>
          {loadingMore ? "正在加载…" : "继续加载来源内容"}
        </button>
      ) : (
        <p className="cka-preview__end">已到达当前来源末尾</p>
      )}
    </article>
  );
}
