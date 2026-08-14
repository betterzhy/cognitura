import { useId } from "react";

interface SourceEntryProps {
  readonly sourceRefs: readonly string[];
}

export function SourceEntry({ sourceRefs }: SourceEntryProps) {
  const headingId = `${useId()}-source-heading`;
  if (sourceRefs.length === 0) {
    throw new Error("MODULE_DEFAULT_READING_SOURCE_REQUIRED");
  }

  return (
    <section
      aria-labelledby={headingId}
      className="module-source-entry"
      data-reading-section="source-entry"
    >
      <div>
        <p className="module-section-label" id={headingId}>
          来源锚点
        </p>
        <p>关键结论可回到正式来源核验。</p>
      </div>
      <button
        className="module-source-entry__action cka-focusable"
        type="button"
        data-source-refs={JSON.stringify(sourceRefs)}
      >
        查看 {sourceRefs.length} 条来源证据
      </button>
    </section>
  );
}
