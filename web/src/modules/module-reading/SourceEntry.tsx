interface SourceEntryProps {
  readonly sourceRefs: readonly string[];
}

export function SourceEntry({ sourceRefs }: SourceEntryProps) {
  if (sourceRefs.length === 0) {
    throw new Error("MODULE_DEFAULT_READING_SOURCE_REQUIRED");
  }

  return (
    <button
      type="button"
      data-reading-section="source-entry"
      data-source-refs={JSON.stringify(sourceRefs)}
    >
      查看 {sourceRefs.length} 条来源证据
    </button>
  );
}
