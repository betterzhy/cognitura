import { useState } from "react";

export interface SourceUploadPanelProps {
  busy: boolean;
  onUpload: (file: File, idempotencyKey: string) => Promise<void>;
}

export function SourceUploadPanel({ busy, onUpload }: SourceUploadPanelProps) {
  const [file, setFile] = useState<File | null>(null);
  const [idempotencyKey, setIdempotencyKey] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (!file || !idempotencyKey.trim()) {
      setError("请选择 DOCX 文件并填写幂等键。");
      return;
    }
    setError(null);
    await onUpload(file, idempotencyKey.trim());
  }

  return (
    <section className="cka-ingestion__upload" aria-labelledby="source-upload-title">
      <div className="cka-ingestion__eyebrow">来源输入</div>
      <h2 id="source-upload-title">添加一份结构化来源</h2>
      <p className="cka-ingestion__lede">
        上传 DOCX 后，系统会先保留来源结构，再生成可核验的连续预览。
      </p>
      <form onSubmit={submit}>
        <label className="cka-field">
          <span>选择 DOCX 文件</span>
          <input
            type="file"
            accept=".docx,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            disabled={busy}
            onChange={(event) => setFile(event.currentTarget.files?.[0] ?? null)}
          />
        </label>
        {file ? (
          <div className="cka-file-chip">
            <span aria-hidden="true">DOCX</span>
            <strong>{file.name}</strong>
            <small>{Math.max(1, Math.ceil(file.size / 1024))} KB</small>
          </div>
        ) : null}
        <label className="cka-field">
          <span>幂等键</span>
          <input
            value={idempotencyKey}
            onChange={(event) => setIdempotencyKey(event.currentTarget.value)}
            placeholder="例如：redis-notes-2026-08"
            disabled={busy}
          />
        </label>
        <p className="cka-field__hint">相同键与相同内容会安全复用，不会重复登记。</p>
        {error ? <p className="cka-inline-error">{error}</p> : null}
        <button className="cka-button cka-button--primary" type="submit" disabled={busy}>
          {busy ? "正在校验来源…" : "上传来源"}
        </button>
      </form>
      <p className="cka-ingestion__privacy">
        <span aria-hidden="true">✓</span> 当前阶段只接受 DOCX；来源标识不会显示在页面正文中。
      </p>
    </section>
  );
}
