export const DOCX_MEDIA_TYPE =
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

export interface UploadResult {
  sourceDocumentId: string;
  sourceIngestionDisplayStatus: string;
  contentSha256: string;
  receivedAt: string;
}

export interface ProcessingResult {
  sourceDocumentId: string;
  sourceProcessingRevisionId: string;
  sourceProcessingRevisionStatus: string;
  sourceIngestionDisplayStatus: string;
  pollLocation: string;
  reused: boolean;
}

export interface Omission {
  sourcePart: string;
  sourceElementIndex: number;
  errorCode: string;
  userVisibleDescription: string;
}

export interface RevisionStatus {
  sourceDocumentId: string;
  sourceProcessingRevisionId: string;
  parserProfileVersion: string;
  sourceProcessingRevisionStatus: string;
  sourceIngestionDisplayStatus: string;
  parseCompleteness: "COMPLETE" | "PARTIAL" | null;
  omissions: Omission[];
  publishedBlockSetDigest: string | null;
  omissionsDigest: string | null;
  partialAcceptanceStatus: "NOT_APPLICABLE" | "PENDING" | "ACCEPTED" | null;
  failureCode: string | null;
  failureDetail: string | null;
  startedAt: string | null;
  completedAt: string | null;
}

export type SourceBlockPayload =
  | { text: string; level: number; styleName: string | null }
  | { text: string; styleName: string | null }
  | { listInstanceId: string; itemLevel: number; itemOrdinal: number; markerText: string | null; text: string }
  | { rows: Array<{ rowIndex: number; cells: Array<{ columnIndex: number; rowSpan: number; columnSpan: number; text: string }> }> }
  | { relationshipMode: "INTERNAL" | "EXTERNAL"; externalTargetLiteralSha256: string | null; mediaType: string | null; byteLength: number | null; contentSha256: string | null; securityDisclosure: string | null };

export interface SourcePreviewItem {
  documentBlockId: string;
  documentBlockRef: string;
  blockType: "HEADING" | "PARAGRAPH" | "LIST" | "TABLE" | "IMAGE";
  sourceOrder: number;
  sectionPath: string[];
  pageNumber: number | null;
  pageEvidence: unknown | null;
  sourceAnchor: {
    anchorKind: string;
    parentBlockId: string | null;
    textOffset: number | null;
    childOrdinal: number | null;
    rowIndex: number | null;
    columnIndex: number | null;
  };
  contentHash: string;
  payload: SourceBlockPayload;
  affectedByOmission: boolean;
}

export interface SourcePreviewPage {
  sourceDocumentId: string;
  sourceProcessingRevisionId: string;
  originalFileName: string;
  parseCompleteness: "COMPLETE" | "PARTIAL";
  publishedBlockSetDigest: string;
  omissionsDigest: string;
  incomplete: boolean;
  partialWarning: string | null;
  omissions: Omission[];
  items: SourcePreviewItem[];
  nextCursor: string | null;
}

export interface PartialAcceptanceResult {
  sourceDocumentId: string;
  sourceProcessingRevisionId: string;
  partialAcceptanceStatus: "ACCEPTED";
  partialAcceptedAt: string;
  acceptedBy: string;
  consumptionEligible: boolean;
  idempotentReplay: boolean;
}

interface ApiErrorBody {
  errorCode?: string;
  message?: string;
  retryable?: boolean;
}

export class SourceApiError extends Error {
  constructor(
    readonly code: string,
    readonly retryable: boolean,
    message: string,
  ) {
    super(message);
  }
}

function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  }
  return value as Record<string, unknown>;
}

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, init);
  const body: unknown = await response.json().catch(() => null);
  if (!response.ok) {
    const error = object(body) as ApiErrorBody;
    throw new SourceApiError(
      typeof error.errorCode === "string" ? error.errorCode : "REQUEST_FAILED",
      error.retryable === true,
      typeof error.message === "string" ? error.message : "请求未能完成。",
    );
  }
  return object(body) as T;
}

function sourcePath(sourceDocumentId: string, suffix = "") {
  return `/api/v1/source-documents/${encodeURIComponent(sourceDocumentId)}${suffix}`;
}

function fileBytes(file: File): Promise<ArrayBuffer> {
  if (typeof file.arrayBuffer === "function") return file.arrayBuffer();
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new SourceApiError("FILE_READ_FAILED", false, "无法读取所选文件。"));
    reader.onload = () => resolve(reader.result as ArrayBuffer);
    reader.readAsArrayBuffer(file);
  });
}

async function sha256(file: File): Promise<string> {
  const source = new Uint8Array(await fileBytes(file));
  const bytes = Uint8Array.from(source);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function uploadSource(workspaceId: string, file: File, idempotencyKey: string) {
  if (file.type !== DOCX_MEDIA_TYPE) {
    throw new SourceApiError("UNSUPPORTED_MEDIA_TYPE", false, "请选择 DOCX 文件。");
  }
  const command = {
    idempotencyKey,
    originalFileName: file.name,
    declaredMediaType: file.type,
    declaredByteLength: file.size,
    contentSha256: await sha256(file),
  };
  const form = new FormData();
  form.append("command", new Blob([JSON.stringify(command)], { type: "application/json" }));
  form.append("file", file);
  return request<UploadResult>(
    `/api/v1/workspaces/${encodeURIComponent(workspaceId)}/source-documents`,
    { method: "POST", body: form },
  );
}

export function startProcessing(sourceDocumentId: string, parserProfileVersion: string) {
  return request<ProcessingResult>(sourcePath(sourceDocumentId, "/processing-revisions"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ sourceDocumentId, parserProfileVersion }),
  });
}

export function getRevisionStatus(pollLocation: string) {
  if (!/^\/api\/v1\/source-documents\/[^/]+\/processing-revisions\/[^/]+$/.test(pollLocation)) {
    throw new SourceApiError("POLL_LOCATION_INVALID", false, "处理状态地址无效。");
  }
  return request<RevisionStatus>(pollLocation);
}

export function getPreview(sourceDocumentId: string, revisionId: string, after?: string | null) {
  const query = new URLSearchParams({ limit: "50" });
  if (after) query.set("after", after);
  return request<SourcePreviewPage>(
    sourcePath(sourceDocumentId, `/processing-revisions/${encodeURIComponent(revisionId)}/blocks?${query}`),
  );
}

export function acceptPartial(
  sourceDocumentId: string,
  revisionId: string,
  blockSetDigest: string,
  omissionsDigest: string,
  idempotencyKey: string,
) {
  return request<PartialAcceptanceResult>(
    sourcePath(sourceDocumentId, `/processing-revisions/${encodeURIComponent(revisionId)}/partial-acceptance`),
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ blockSetDigest, omissionsDigest, idempotencyKey, decision: "ACCEPT_PARTIAL" }),
    },
  );
}
