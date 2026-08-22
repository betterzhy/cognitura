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

function exact(value: unknown, keys: string[]): Record<string, unknown> {
  const record = object(value);
  const actual = Object.keys(record).sort();
  const expected = [...keys].sort();
  if (actual.length !== expected.length || actual.some((key, index) => key !== expected[index])) {
    throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  }
  return record;
}

function textValue(value: unknown): string {
  if (typeof value !== "string" || !value) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return value;
}

function contentTextValue(value: unknown): string {
  if (typeof value !== "string") throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return value;
}

function nullableText(value: unknown): string | null {
  return value === null ? null : textValue(value);
}

function booleanValue(value: unknown): boolean {
  if (typeof value !== "boolean") throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return value;
}

function numberValue(value: unknown): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < 0) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return value;
}

function hashValue(value: unknown): string {
  const valueText = textValue(value);
  if (!/^[0-9a-f]{64}$/.test(valueText)) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return valueText;
}

function optionalHash(value: unknown): string | null {
  return value === null ? null : hashValue(value);
}

function stringArray(value: unknown): string[] {
  if (!Array.isArray(value)) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return value.map(textValue);
}

function enumValue<T extends string>(value: unknown, allowed: readonly T[]): T {
  const candidate = textValue(value);
  if (!allowed.includes(candidate as T)) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return candidate as T;
}

function decodeOmission(value: unknown): Omission {
  const item = exact(value, ["sourcePart", "sourceElementIndex", "errorCode", "userVisibleDescription"]);
  return {
    sourcePart: textValue(item.sourcePart),
    sourceElementIndex: numberValue(item.sourceElementIndex),
    errorCode: textValue(item.errorCode),
    userVisibleDescription: textValue(item.userVisibleDescription),
  };
}

function decodePayload(blockType: SourcePreviewItem["blockType"], value: unknown): SourceBlockPayload {
  if (blockType === "HEADING") {
    const payload = exact(value, ["text", "level", "styleName"]);
    const level = numberValue(payload.level);
    if (level < 1 || level > 9) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
    return { text: textValue(payload.text), level, styleName: nullableText(payload.styleName) };
  }
  if (blockType === "PARAGRAPH") {
    const payload = exact(value, ["text", "styleName"]);
    return { text: contentTextValue(payload.text), styleName: nullableText(payload.styleName) };
  }
  if (blockType === "LIST") {
    const payload = exact(value, ["listInstanceId", "itemLevel", "itemOrdinal", "markerText", "text"]);
    return { listInstanceId: textValue(payload.listInstanceId), itemLevel: numberValue(payload.itemLevel), itemOrdinal: numberValue(payload.itemOrdinal), markerText: nullableText(payload.markerText), text: contentTextValue(payload.text) };
  }
  if (blockType === "TABLE") {
    const payload = exact(value, ["rows"]);
    if (!Array.isArray(payload.rows)) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
    return { rows: payload.rows.map((rowValue) => {
      const row = exact(rowValue, ["rowIndex", "cells"]);
      if (!Array.isArray(row.cells)) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
      return { rowIndex: numberValue(row.rowIndex), cells: row.cells.map((cellValue) => {
        const cell = exact(cellValue, ["columnIndex", "rowSpan", "columnSpan", "text"]);
        const rowSpan = numberValue(cell.rowSpan);
        const columnSpan = numberValue(cell.columnSpan);
        if (rowSpan < 1 || columnSpan < 1) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
        return { columnIndex: numberValue(cell.columnIndex), rowSpan, columnSpan, text: contentTextValue(cell.text) };
      }) };
    }) };
  }
  const payload = exact(value, ["relationshipMode", "externalTargetLiteralSha256", "mediaType", "byteLength", "contentSha256", "securityDisclosure"]);
  const relationshipMode = enumValue(payload.relationshipMode, ["INTERNAL", "EXTERNAL"] as const);
  const decoded = {
    relationshipMode,
    externalTargetLiteralSha256: optionalHash(payload.externalTargetLiteralSha256),
    mediaType: nullableText(payload.mediaType),
    byteLength: payload.byteLength === null ? null : numberValue(payload.byteLength),
    contentSha256: optionalHash(payload.contentSha256),
    securityDisclosure: nullableText(payload.securityDisclosure),
  };
  const internalValid = relationshipMode === "INTERNAL" && decoded.externalTargetLiteralSha256 === null && decoded.mediaType !== null && decoded.byteLength !== null && decoded.byteLength > 0 && decoded.contentSha256 !== null && decoded.securityDisclosure === null;
  const externalValid = relationshipMode === "EXTERNAL" && decoded.externalTargetLiteralSha256 !== null && decoded.mediaType === null && decoded.byteLength === null && decoded.contentSha256 === null && decoded.securityDisclosure === "EXTERNAL_RELATIONSHIP_NOT_DEREFERENCED";
  if (!internalValid && !externalValid) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return decoded;
}

function decodePreviewItem(value: unknown): SourcePreviewItem {
  const item = exact(value, ["documentBlockId", "documentBlockRef", "blockType", "sourceOrder", "sectionPath", "pageNumber", "pageEvidence", "sourceAnchor", "contentHash", "payload", "affectedByOmission"]);
  const blockType = enumValue(item.blockType, ["HEADING", "PARAGRAPH", "LIST", "TABLE", "IMAGE"] as const);
  const anchor = exact(item.sourceAnchor, ["anchorKind", "parentBlockId", "textOffset", "childOrdinal", "rowIndex", "columnIndex"]);
  let pageEvidence: unknown | null = null;
  if (item.pageEvidence !== null) {
    const evidence = exact(item.pageEvidence, ["layoutProfileVersion", "layoutEngineVersion", "pageIndex", "evidenceHash"]);
    pageEvidence = { layoutProfileVersion: textValue(evidence.layoutProfileVersion), layoutEngineVersion: textValue(evidence.layoutEngineVersion), pageIndex: numberValue(evidence.pageIndex), evidenceHash: hashValue(evidence.evidenceHash) };
  }
  return {
    documentBlockId: textValue(item.documentBlockId), documentBlockRef: textValue(item.documentBlockRef), blockType,
    sourceOrder: numberValue(item.sourceOrder), sectionPath: stringArray(item.sectionPath),
    pageNumber: item.pageNumber === null ? null : numberValue(item.pageNumber), pageEvidence,
    sourceAnchor: { anchorKind: textValue(anchor.anchorKind), parentBlockId: nullableText(anchor.parentBlockId), textOffset: anchor.textOffset === null ? null : numberValue(anchor.textOffset), childOrdinal: anchor.childOrdinal === null ? null : numberValue(anchor.childOrdinal), rowIndex: anchor.rowIndex === null ? null : numberValue(anchor.rowIndex), columnIndex: anchor.columnIndex === null ? null : numberValue(anchor.columnIndex) },
    contentHash: hashValue(item.contentHash), payload: decodePayload(blockType, item.payload), affectedByOmission: booleanValue(item.affectedByOmission),
  };
}

function decodeUpload(value: unknown): UploadResult {
  const item = exact(value, ["sourceDocumentId", "sourceIngestionDisplayStatus", "contentSha256", "receivedAt"]);
  return { sourceDocumentId: textValue(item.sourceDocumentId), sourceIngestionDisplayStatus: enumValue(item.sourceIngestionDisplayStatus, ["VALIDATING", "TERMINAL_FAILURE"] as const), contentSha256: hashValue(item.contentSha256), receivedAt: textValue(item.receivedAt) };
}

function decodeProcessing(value: unknown): ProcessingResult {
  const item = exact(value, ["sourceDocumentId", "sourceProcessingRevisionId", "sourceProcessingRevisionStatus", "sourceIngestionDisplayStatus", "pollLocation", "reused"]);
  return { sourceDocumentId: textValue(item.sourceDocumentId), sourceProcessingRevisionId: textValue(item.sourceProcessingRevisionId), sourceProcessingRevisionStatus: enumValue(item.sourceProcessingRevisionStatus, ["PARSING", "PARSED", "PREVIEW_READY", "FAILED_RETRYABLE", "FAILED_TERMINAL"] as const), sourceIngestionDisplayStatus: enumValue(item.sourceIngestionDisplayStatus, ["PARSING", "PREVIEW_READY", "RETRYABLE_FAILURE", "TERMINAL_FAILURE"] as const), pollLocation: textValue(item.pollLocation), reused: booleanValue(item.reused) };
}

function decodeRevision(value: unknown): RevisionStatus {
  const item = exact(value, ["sourceDocumentId", "sourceProcessingRevisionId", "parserProfileVersion", "sourceProcessingRevisionStatus", "sourceIngestionDisplayStatus", "parseCompleteness", "omissions", "publishedBlockSetDigest", "omissionsDigest", "partialAcceptanceStatus", "failureCode", "failureDetail", "startedAt", "completedAt"]);
  if (!Array.isArray(item.omissions)) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  return {
    sourceDocumentId: textValue(item.sourceDocumentId), sourceProcessingRevisionId: textValue(item.sourceProcessingRevisionId), parserProfileVersion: textValue(item.parserProfileVersion),
    sourceProcessingRevisionStatus: enumValue(item.sourceProcessingRevisionStatus, ["PARSING", "PARSED", "PREVIEW_READY", "FAILED_RETRYABLE", "FAILED_TERMINAL"] as const), sourceIngestionDisplayStatus: enumValue(item.sourceIngestionDisplayStatus, ["PARSING", "PREVIEW_READY", "RETRYABLE_FAILURE", "TERMINAL_FAILURE"] as const),
    parseCompleteness: item.parseCompleteness === null ? null : enumValue(item.parseCompleteness, ["COMPLETE", "PARTIAL"] as const), omissions: item.omissions.map(decodeOmission),
    publishedBlockSetDigest: optionalHash(item.publishedBlockSetDigest), omissionsDigest: optionalHash(item.omissionsDigest),
    partialAcceptanceStatus: item.partialAcceptanceStatus === null ? null : enumValue(item.partialAcceptanceStatus, ["NOT_APPLICABLE", "PENDING", "ACCEPTED"] as const),
    failureCode: nullableText(item.failureCode), failureDetail: nullableText(item.failureDetail), startedAt: nullableText(item.startedAt), completedAt: nullableText(item.completedAt),
  };
}

function decodePreview(value: unknown): SourcePreviewPage {
  const item = exact(value, ["sourceDocumentId", "sourceProcessingRevisionId", "originalFileName", "parseCompleteness", "publishedBlockSetDigest", "omissionsDigest", "incomplete", "partialWarning", "omissions", "items", "nextCursor"]);
  if (!Array.isArray(item.omissions) || !Array.isArray(item.items)) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  const parseCompleteness = enumValue(item.parseCompleteness, ["COMPLETE", "PARTIAL"] as const);
  const incomplete = booleanValue(item.incomplete);
  if (incomplete !== (parseCompleteness === "PARTIAL")) throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  const omissions = item.omissions.map(decodeOmission);
  const items = item.items.map(decodePreviewItem);
  const partialWarning = nullableText(item.partialWarning);
  if ((incomplete && (omissions.length === 0 || partialWarning === null)) || (!incomplete && (omissions.length !== 0 || partialWarning !== null))) {
    throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  }
  if (items.some((previewItem, index) => index > 0 && previewItem.sourceOrder <= items[index - 1].sourceOrder)) {
    throw new SourceApiError("MALFORMED_RESPONSE", false, "服务返回了无法识别的数据。");
  }
  return { sourceDocumentId: textValue(item.sourceDocumentId), sourceProcessingRevisionId: textValue(item.sourceProcessingRevisionId), originalFileName: textValue(item.originalFileName), parseCompleteness, publishedBlockSetDigest: hashValue(item.publishedBlockSetDigest), omissionsDigest: hashValue(item.omissionsDigest), incomplete, partialWarning, omissions, items, nextCursor: nullableText(item.nextCursor) };
}

function decodeAcceptance(value: unknown): PartialAcceptanceResult {
  const item = exact(value, ["sourceDocumentId", "sourceProcessingRevisionId", "partialAcceptanceStatus", "partialAcceptedAt", "acceptedBy", "consumptionEligible", "idempotentReplay"]);
  return { sourceDocumentId: textValue(item.sourceDocumentId), sourceProcessingRevisionId: textValue(item.sourceProcessingRevisionId), partialAcceptanceStatus: enumValue(item.partialAcceptanceStatus, ["ACCEPTED"] as const), partialAcceptedAt: textValue(item.partialAcceptedAt), acceptedBy: textValue(item.acceptedBy), consumptionEligible: booleanValue(item.consumptionEligible), idempotentReplay: booleanValue(item.idempotentReplay) };
}

async function request<T>(url: string, init: RequestInit | undefined, decode: (value: unknown) => T): Promise<T> {
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
  return decode(body);
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
    { method: "POST", body: form }, decodeUpload,
  );
}

export function startProcessing(sourceDocumentId: string, parserProfileVersion: string) {
  return request<ProcessingResult>(sourcePath(sourceDocumentId, "/processing-revisions"), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ sourceDocumentId, parserProfileVersion }),
  }, decodeProcessing);
}

export function getRevisionStatus(pollLocation: string) {
  if (!/^\/api\/v1\/source-documents\/[^/]+\/processing-revisions\/[^/]+$/.test(pollLocation)) {
    throw new SourceApiError("POLL_LOCATION_INVALID", false, "处理状态地址无效。");
  }
  return request<RevisionStatus>(pollLocation, undefined, decodeRevision);
}

export function getPreview(sourceDocumentId: string, revisionId: string, after?: string | null) {
  const query = new URLSearchParams({ limit: "50" });
  if (after) query.set("after", after);
  return request<SourcePreviewPage>(
    sourcePath(sourceDocumentId, `/processing-revisions/${encodeURIComponent(revisionId)}/blocks?${query}`),
    undefined,
    decodePreview,
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
    }, decodeAcceptance,
  );
}
