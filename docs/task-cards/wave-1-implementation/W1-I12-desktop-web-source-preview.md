# W1-I12 Desktop Web Source Preview

```text
TaskCardID = W1-I12
CardKind = IMPLEMENTATION
Status = BLOCKED_BY_DEPENDENCY
Gate = W1-IG12 DesktopWebSourcePreview
Risk = MEDIUM
DependsOn = W1-I10,W1-I11
PrimaryBoundary = WEB_DOCUMENT_INGESTION
ProductionFileLimit = 8
ProductionWriteSetException = NONE
BusinessImplementationAuthorization = REQUIRED_BEFORE_READY
FormalDatabaseGate = NOT_APPLICABLE
RemotePush = NOT_AUTHORIZED
ReviewRoute = deep_reviewer
```

## 1. 目标

实现 Desktop Web 最小上传、processing、preview 和 partial-confirmation 投影；只消费
正式 API，不生成或改写来源事实。

## 2. 前置条件与输入

- I10、I11 均 DONE，query 与 acceptance HTTP 合同固定。
- Desktop Web 为主要交付面；小屏只保证安全可读。
- 不修改现有认知 Renderer 或 Module 默认阅读切片。

## 3. 写集

```text
WriteSet = web/src/modules/document-ingestion/SourceIngestionPage.tsx
WriteSet = web/src/modules/document-ingestion/SourceUploadPanel.tsx
WriteSet = web/src/modules/document-ingestion/ProcessingStatus.tsx
WriteSet = web/src/modules/document-ingestion/SourcePreview.tsx
WriteSet = web/src/modules/document-ingestion/PartialAcceptancePanel.tsx
WriteSet = web/src/modules/document-ingestion/source-ingestion.css
WriteSet = web/src/modules/document-ingestion/api.ts
WriteSet = web/src/modules/document-ingestion/index.ts
WriteSet = web/src/modules/document-ingestion/SourceIngestionPage.test.tsx
WriteSet = web/src/modules/document-ingestion/SourcePreview.test.tsx
ForbiddenWriteSet = web/src/modules/module-reading/**
ForbiddenWriteSet = web/src/App.tsx
ForbiddenWriteSet = server/**,schemas/**,raw/**,.idea/**
ForbiddenWriteSet = SUMMARY_RENDERER_OR_SOURCE_FACT_REWRITE
```

## 4. 执行步骤

1. RED：上传、processing、完整/不完整 preview、受影响块与 digest 漂移确认先失败。
2. GREEN：按 API 原序投影 typed payload；incomplete 顶部警告和受影响块标记必须可见。
3. partial confirmation 只发送正式 tuple，不在客户端补算来源事实。

## 5. 验证命令

```bash
cd web && corepack pnpm test -- src/modules/document-ingestion
cd web && corepack pnpm build
scripts/verify-wave1-implementation
git diff --check
git status --short
```

## 6. Gate 与完成定义

上传、processing、preview、incomplete 标记和 partial confirmation 正负例通过；组件不生成
摘要、不调用 Renderer、不改写来源内容，生产文件恰不超过 8。

## 7. 提交与审查

```bash
git add web/src/modules/document-ingestion
git commit -m "feat: add desktop source preview"
```

固定提交由新的 `deep_reviewer` 审查；零发现 GO 前不得释放 I13。
