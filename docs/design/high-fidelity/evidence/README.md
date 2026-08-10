# Cognitura 高保真视觉证据

本目录只保存 `docs/` 下确定性非生产原型的视觉证据。截图不是 Canonical Knowledge
Source，不授权业务实现，也不能单独证明可用性或实现阶段 PASS。

## HV-D00 基础证据

```text
Artifact = visual-foundation-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=visual-foundation
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_FOUNDATION_FIXTURE
EvidenceMeaning = VISUAL_TOKEN_AND_PROTOTYPE_GOVERNANCE_BASELINE_ONLY
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
HighFidelityVisualDesign = PASS
HighFidelityVisualValidation = PASS
HighFidelityUsabilityValidation = PASS
HighFidelityStateAcceptance = PASS
ImplementationValidation = NOT_RUN
```

验收时必须检查 PNG 实际尺寸和视觉内容，确认它显示 Reading First 连续文档、低权重
层级轨道、单一主要认知投影、行内 Relation、按需 SourceEvidence 入口、可见焦点合同，
且没有常驻治理侧栏、HTTP、持久化或生产依赖。

## HV-D01 Module 默认阅读证据

```text
Artifact = module-default-reading-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=module-default
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = CognitiveModuleDefaultReading
ValidationStage = HIGH_FIDELITY_VISUAL
EvidenceMeaning = ZERO_INTERACTION_MODULE_COGNITIVE_CLOSURE
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
ContentSource = EMBEDDED_DETERMINISTIC_SYNTHETIC_MECHANISM
RawDocxAccess = FORBIDDEN
NetworkAccess = FORBIDDEN
Persistence = FORBIDDEN
PersistentGovernanceSidePanels = 0
PrimaryVisualProjectionCount = 1
KeyRelationCount = 2
KnowledgeElementEntry = ON_DEMAND
SourceEvidenceEntry = ON_DEMAND
HighFidelityModuleDefaultReading = PASS
```

原始分辨率截图与 DOM 同时显示 CoreQuestion、CoreConclusion、连续叙事、
PrimaryCognitiveSpine、单一机制投影、Conditions、Results、Boundaries/Exceptions、
两条 Relation、KnowledgeElement 定位/按需展开入口和 SourceEvidence 按需入口。
键盘入口使用语义化 `button` 与明确 `aria-label`，并继承既定 focus token。该证据
仅使 `RF-AC-02,04,05,06,08,11,12` 的 `HIGH_FIDELITY_VISUAL` 阶段为 PASS；
其他 RF-AC、异常、整体视觉、可用性与实现状态不变。

## HV-D02 Relation 聚焦与来源核验证据

```text
Artifact = module-relation-focus-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=relation-focus
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = RelationFocus
ValidationStage = HIGH_FIDELITY_VISUAL
EvidenceMeaning = SINGLE_PRIMARY_RELATION_WITH_SECONDARY_ENDPOINTS_AND_ORIGIN_RETURN
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
StateCode = RELATION_PINNED_FOCUS
PrimaryStableFocusCount = 1
EndpointCount = 2
IndependentFactCount = 0
EscapeFocusReturn = relation-origin-anchor

Artifact = module-source-verification-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=source-verification
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = SourceEvidenceVerification
ValidationStage = HIGH_FIDELITY_VISUAL
EvidenceMeaning = CANONICAL_TARGET_SUPPORT_MATRIX_WITH_CONFLICT_GAP_AND_ORIGIN_RETURN
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
StateCode = FULL_VERIFICATION_WORKSPACE
CanonicalTarget = rel-read-view-visibility
OriginalReadingAnchor = RETAINED
IndependentFactCount = 0
HighFidelityFocusAndSource = PASS
```

两张证据均使用内嵌确定性合成内容，不读取 Golden Case DOCX，不访问网络、
`localStorage`、`sessionStorage`、Cookie 或数据库。
真实 DOM 与交互探针核验唯一主聚焦、origin anchor、完整 Relation 陈述、两个次级
端点、支持范围、冲突、来源缺口、Enter/点击等价和 Escape 焦点归还。该证据只使
`RF-AC-03,07,09,16` 的 `HIGH_FIDELITY_VISUAL` 阶段为 PASS；正式 RF 输入行、异常、
整体视觉、可用性与实现状态仍不变。

HV-D05 第二阶段补充求值后转换探针：Quick Source 的“进入完整核验”必须通过真实
History 导航到 `source-verification`，确认裁决必须改变真实 Document、History 与
可见反馈。该补充只形成 `PASS_HIGH_FIDELITY_USABILITY_ONLY` 观察，不改正式 RF 行。

## HV-D03 修订、影响与恢复证据

```text
Artifact = module-revision-impact-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=revision-impact
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = RevisionAndImpact
ValidationStage = HIGH_FIDELITY_VISUAL
EvidenceMeaning = BEFORE_AFTER_THREE_LANE_IMPACT_WITH_EXPANDED_BLOCKER
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
StateCode = REVISION_MODE+COMMIT_BLOCKED
ImpactLaneCount = 3
CommitControl = DISABLED
DraftPreserved = YES

Artifact = module-recovery-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=partial-failure
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = Recovery
ValidationStage = HIGH_FIDELITY_VISUAL
EvidenceMeaning = CANONICAL_SAVED_PARTIAL_FAILURE_AND_EXPLICIT_RECOVERY
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
StateCode = CANONICAL_SAVED+PARTIAL_FAILURE
CanonicalVersion = v13
ChangeSet = cs-1042
ProcessingStateCount = 4
StaleProjection = EXPLICIT_OUTDATED
SubmitUnknownDisposition = QUERY_ORIGINAL_RESULT_WITH_SAME_KEY
RevertDisposition = CREATE_NEW_REVERT_CHANGESET

Artifact = module-conflicted-draft-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=conflicted-draft
Viewport = 1440x1100
CaptureKind = CHROME_HEADLESS_LOCAL_FILE
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = Recovery
ValidationStage = HIGH_FIDELITY_VISUAL
EvidenceMeaning = BEFORE_LATEST_DRAFT_CONFLICT_WITH_REBASE_AND_DRAFT_PROTECTION
FreshnessCheck = CHROME_RECAPTURE_1440x1100_BYTE_IDENTICAL
StateCode = CONFLICTED_DRAFT+COMMIT_BLOCKED
DraftPreserved = YES
HighFidelityRevisionAndRecovery = PASS
```

`module-recovery-desktop.png` 是 HV-D03 唯一主证据；其余两张是必要补充证据。
浏览器探针验证三类影响同屏、默认展开 Blocker、真实禁用提交、正式保存边界、四类
后处理、显式 stale、同幂等键结果查询、失败通道重试、刷新恢复、Revert 新变更、
冲突重新基线化与 Escape 分层焦点归还。该证据只使 `RF-AC-13,14,17,18` 的
`HIGH_FIDELITY_VISUAL` 阶段为 PASS；正式 RF/Exception 输入行、整体视觉、可用性和
实现状态仍不变。

HV-D05 第二阶段补充了真实浏览器 History 生命周期：恢复动作写入
`history.state`，随后实际 reload、back、forward，并核对 Workspace、draft、
processing、semantic anchor 与焦点；它不使用 `localStorage`、`sessionStorage`、
Cookie、网络或数据库。修订、部分失败与冲突草稿中的关键按钮还必须改变真实 DOM
和 History 状态。20 个正式异常 ID 逐一运行非生产恢复 harness，验证可见反馈、准确
恢复动作及焦点落点。所有结果仅作为高保真可用性观察，正式 `RFAcceptance`、
`ExceptionAcceptance`、整体可用性和实现仍为 `NOT_RUN`。

## HV-D04 跨层、小屏与静态导出证据

```text
Artifact = knowledge-landscape-theme-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=domain-default
Viewport = 1440x1100
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = KnowledgeLandscapeAndKnowledgeTheme
FreshnessCheck = CHROME_RECAPTURE_BYTE_IDENTICAL
CanonicalHierarchy = KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement

Artifact = cross-domain-reading-desktop.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=theme-default
Viewport = 1440x1100
ArtifactStatus = CAPTURED_SUPPORTING_HIGH_FIDELITY_VISUAL
EvidenceMeaning = MECHANISM_AND_RULE_POLICY_RETAIN_ONE_CANONICAL_HIERARCHY

Artifact = module-default-reading-small-screen.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=module-small-screen
Viewport = 390x844
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = SmallScreenSafeReadable
PrimarySurface = DOCUMENT_FLOW
PersistentSidePanelCount = 0
TouchTargetMinimum = 44px

Artifact = static-export-example.png
PrototypeURL = docs/design/high-fidelity/prototype/index.html?state=static-export
Viewport = 1200x1600
ArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
EvidenceClass = StaticExport
CompanionManifest = static-export-manifest.json
MachineIdentity = OBJECT_RELATION_SOURCE_STABLE
RawTechnicalIdsVisible = NO
ImageCanonicalAuthority = NONE
HighFidelityCrossLayerResponsiveAndExport = PASS
```

主证据同时呈现 LandscapeThesis、核心 Theme、职责、UnderstandingRoute 和
ThemeClosure；跨域补图证明机制与规则/政策不会创建第五层。小屏 fixture 使用单列
连续正文和按需 overlay，Escape 返回原 KnowledgeElement 入口。静态导出正文保持
核心问题、解释、Relation、边界和来源脚注，稳定 ID 仅由 companion manifest 与 DOM
属性携带。该证据使 `RF-AC-01,10,15,19` 的视觉阶段为 PASS；`RF-AC-20` 的
supporting evidence 与固定候选观察已由 `HV-D05` 关闭为高保真 PASS，正式输入行
仍保持历史 `NOT_RUN`，实现也未执行。

## 后续主证据与 RF Owner

```text
CanonicalPrimaryArtifact = HV-D03|docs/design/high-fidelity/evidence/module-recovery-desktop.png
CanonicalPrimaryArtifact = HV-D04|docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png
RFOwner = HV-D01|RF-AC-02,04,05,06,08,11,12
RFOwner = HV-D02|RF-AC-03,07,09,16
RFOwner = HV-D03|RF-AC-13,14,17,18
RFOwner = HV-D04|RF-AC-01,10,15,19
RFOwner = HV-D05|RF-AC-20
```

前四卡只能关闭各自 Owner 行；`HV-D04` 只捕获 `RF-AC-20` 的 supporting visual
evidence，最终由 `HV-D05` 固定候选审查关闭独立高保真观察，不改写正式输入合同。
