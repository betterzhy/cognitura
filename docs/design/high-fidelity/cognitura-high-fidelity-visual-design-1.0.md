# Cognitura 高保真视觉设计 1.0

```text
CanonicalProjectName = Cognitura
DesignKind = HIGH_FIDELITY_VISUAL_DESIGN
DesignStatus = CROSS_LAYER_RESPONSIVE_EXPORT_EVIDENCE_ESTABLISHED
ContractSource = Cognitura-High-Fidelity-Interaction-Specialty-1.0
ContractGate = HF-DG4 PASS
FoundationGate = HV-D00 PASS
ModuleDefaultReadingGate = HV-D01 PASS
HighFidelityModuleDefaultReading = PASS
HighFidelityFocusAndSource = PASS
HighFidelityRevisionAndRecovery = PASS
HighFidelityCrossLayerResponsiveAndExport = PASS
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
PrototypeKind = DOCUMENTATION_ONLY_NON_PRODUCTION_FIXTURE
FixtureDataSource = EMBEDDED_DETERMINISTIC_DATA
FixtureStateTransport = URL_QUERY_ONLY
NetworkAccess = FORBIDDEN
PersistentUserData = FORBIDDEN
DesktopViewport = 1440x1100
SmallScreenViewport = 390x844
DesktopContentThreshold = 1180px
CompactLayoutThreshold = 900px
FocusRingToken = --focus-ring
DocumentWidthToken = --document-width
HierarchyRailToken = --hierarchy-rail-width
SourceMarkerToken = --source-marker
StaleToken = --status-stale
ErrorToken = --status-error
```

本文件是后续 HV 卡共同消费的视觉基础，不是生产页面规格或前端实现选择。
`HV-D00` 只建立 token、响应式阈值、fixture 治理和基础截图；`HV-D01` 只建立
Module 默认阅读证据并关闭其七项视觉 Owner。Relation、SourceEvidence、Revision、
Recovery、跨层、小屏与导出的真实视觉验收仍由 `HV-D02..D04` 逐卡完成，最终
可用性由 `HV-D05` 固定候选审查。

## 1. Reading First 构图

默认桌面视口由三层组成：低权重的层级轨道、居中的连续文档、附着于陈述的轻量
状态。层级轨道只负责 `KnowledgeLandscape → KnowledgeTheme → CognitiveModule →
KnowledgeElement` 定位，不承担来源、修订、关系治理或统计；它不是治理侧栏。

```text
PrimarySurface = CONTINUOUS_DOCUMENT_FLOW
DefaultReadingPersistentSidePanels = 0
DefaultReadingPermanentToolbars = 0
SourceEvidence = ON_DEMAND_INLINE_ENTRY
RelationTreatment = INLINE_STATEMENT_OR_LOCAL_FOCUS
PrimaryVisualProjectionPerCognitiveSection <= 1
DefaultReadingPersistentPrimaryActionsPerPage <= 2
```

正文最大宽度由 `--document-width` 控制。标题、结论、连续解释、主要认知投影、
条件与边界按阅读顺序出现；任何来源或关系入口都不能替代正文中的核心理解。

## 2. 视觉 Token

### 2.1 字体与层级

```text
ReadingFontToken = --font-reading
InterfaceFontToken = --font-interface
DisplaySizeToken = --text-display
TitleSizeToken = --text-title
BodySizeToken = --text-body
CaptionSizeToken = --text-caption
```

阅读字体使用本机衬线字体回退，帮助连续叙事保持稳定节奏；界面标签、层级轨道、
来源标记与状态使用无衬线字体。正文与界面语气通过字体、字号和间距共同区分，
不得只靠颜色。

### 2.2 间距、版心与轨道

```text
SpacingUnit = 4px
SectionSpacingToken = --space-section
DocumentWidthToken = --document-width
HierarchyRailToken = --hierarchy-rail-width
ReadingLineLength = 62ch..74ch
```

`--space-section` 分隔认知目的，不把每个段落包成卡片。层级轨道宽度固定在
`--hierarchy-rail-width`，正文在大屏居中；轨道缩合时保留四层当前位置的线性说明。

### 2.3 色彩与语义

```text
InkToken = --color-ink
MutedInkToken = --color-ink-muted
PaperToken = --color-paper
AccentToken = --color-accent
SourceMarkerToken = --source-marker
StaleToken = --status-stale
ErrorToken = --status-error
```

状态必须同时拥有文本或图形线索。`--status-stale` 表示投影过期但 Canonical 可能
已经保存；`--status-error` 表示失败或阻断。二者不得互换，也不得把错误伪装为空。

### 2.4 焦点与无障碍

```text
FocusRingToken = --focus-ring
FocusIndicator = 3px_SOLID_WITH_OFFSET
ColorOnlyState = FORBIDDEN
MinimumTouchTarget = 44px
KeyboardOrder = DOCUMENT_ORDER
EscapeRestoresStableFocus = REQUIRED_FOR_APPLICABLE_FIXTURES
```

所有可交互来源标记、关系入口和模式入口必须有 `:focus-visible`。焦点环与背景保持
可辨识对比，不能通过移除 outline 获得视觉整洁。

## 3. 响应式阈值

```text
ViewportRule = ABOVE_1180|RAIL_AND_DOCUMENT
ViewportRule = 901_TO_1180|COMPACT_RAIL_AND_DOCUMENT
ViewportRule = AT_OR_BELOW_900|SINGLE_DOCUMENT_FLOW
SmallScreenPersistentSidePanel = FORBIDDEN
SmallScreenAuxiliaryWorkspace = TEMPORARY_OVERLAY_OR_ROUTE
```

`1180px` 是桌面内容压缩阈值，`900px` 是单列文档阈值。小屏不缩放桌面工作台，
层级轨道改为文档前置路径，辅助 Workspace 必须按需出现并保留返回 Anchor。

## 4. 视觉原语

- Hierarchy rail：低权重位置轨道，不计入治理面板。
- Conclusion lead：由左边界线和短标签强调核心结论，不使用大卡片。
- Mechanism flow：单一主投影，最多七个同时高权重对象。
- Inline relation：自然语言陈述加细方向线，端点不得与 Relation 同权。
- Source marker：附着陈述的轻量入口，默认不展开 SourceEvidence Workspace。
- Status attachment：`stale`、`error`、`pending` 只在改变理解时显示。

## 5. 确定性 Fixture 状态

以下 ID 是后续卡的唯一 URL `state` 输入。`HV-D00` 只实现并捕获
`visual-foundation`；其余 ID 先登记，不表示相应证据存在或 Gate 已执行。

```text
FixtureState = visual-foundation
FixtureState = module-default
FixtureState = relation-focus
FixtureState = source-verification
FixtureState = revision-impact
FixtureState = partial-failure
FixtureState = conflicted-draft
FixtureState = domain-default
FixtureState = theme-default
FixtureState = module-small-screen
FixtureState = static-export
```

夹具数据必须内嵌、确定、可离线读取。状态只由 `?state=<id>` 选择；禁止 HTTP、
WebSocket、浏览器存储、Cookie、server/web 导入、HTML/JS/CSS 外部网络资源或对用户
数据的任何持久化。未知 `state` 必须呈现 `REJECTED_UNKNOWN_STATE`，不得回退到
`visual-foundation` 或其他已登记夹具。

## 6. 截图合同

```text
FoundationArtifact = docs/design/high-fidelity/evidence/visual-foundation-desktop.png
FoundationArtifactState = visual-foundation
FoundationArtifactViewport = 1440x1100
FoundationArtifactStatus = CAPTURED_FOUNDATION_FIXTURE
FoundationArtifactMeaning = TOKEN_AND_GOVERNANCE_BASELINE_ONLY
FoundationArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
```

文件命名采用 `<semantic-state>-<viewport>.png`；证据 README 记录 URL、视口、
捕获边界和验收含义。验证器必须用当前 HTML/CSS/JS 在 1440×1100 重新捕获临时 PNG，
并与提交证据逐字节一致；截图只能证明所属 HV 卡的视觉结果，不能推导可用性或实现。

### 6.1 HV-D01 Module 默认阅读证据

```text
ModuleDefaultReadingArtifact = docs/design/high-fidelity/evidence/module-default-reading-desktop.png
ModuleDefaultReadingArtifactState = module-default
ModuleDefaultReadingArtifactViewport = 1440x1100
ModuleDefaultReadingArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
ModuleDefaultReadingArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
ModuleDefaultReadingContentSource = EMBEDDED_DETERMINISTIC_SYNTHETIC_MECHANISM
ModuleDefaultReadingRawDocxAccess = FORBIDDEN
ModuleDefaultReadingNetworkAccess = FORBIDDEN
ModuleDefaultReadingPersistence = FORBIDDEN
ModuleDefaultReadingPrimaryVisualProjectionCount = 1
ModuleDefaultReadingPersistentGovernanceSidePanels = 0
ModuleDefaultReadingKeyRelationCount = 2
ModuleDefaultReadingKnowledgeElementEntry = ON_DEMAND
ModuleDefaultReadingSourceEvidenceEntry = ON_DEMAND
```

截图与求值后 DOM 共同证明 CoreQuestion、CoreConclusion、连续解释、
PrimaryCognitiveSpine、单一机制投影、Conditions、Results、Boundaries/Exceptions、
两条 Relation、KnowledgeElement 定位/展开入口和 SourceEvidence 按需入口。默认正文
没有卡片瀑布、长文章退化、常驻治理侧栏或 Perspective 依赖；所有按钮继承既定
`:focus-visible` 与 44px 触达合同。

### 6.2 HV-D02 Relation Focus 与来源核验证据

```text
RelationFocusArtifact = docs/design/high-fidelity/evidence/module-relation-focus-desktop.png
RelationFocusArtifactState = relation-focus
RelationFocusArtifactViewport = 1440x1100
RelationFocusArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
RelationFocusArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
RelationFocusStateCode = RELATION_PINNED_FOCUS
RelationFocusPrimaryStableFocusCount = 1
RelationFocusEndpointCount = 2
RelationFocusIndependentFactCount = 0
RelationFocusEscapeReturn = relation-origin-anchor
SourceVerificationArtifact = docs/design/high-fidelity/evidence/module-source-verification-desktop.png
SourceVerificationArtifactState = source-verification
SourceVerificationArtifactViewport = 1440x1100
SourceVerificationArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
SourceVerificationArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
SourceVerificationStateCode = FULL_VERIFICATION_WORKSPACE
SourceVerificationCanonicalTarget = rel-read-view-visibility
SourceVerificationOriginalReadingAnchor = RETAINED
SourceVerificationIndependentFactCount = 0
```

Relation 聚焦中只有完整 Relation 陈述是稳定主焦点；起点、终点、原 Module 与
PrimaryCognitiveSpine 都是次级上下文。来源核验 Workspace 保留相同 Canonical
Target 和原阅读 Anchor，以支持矩阵区分直接支持、结构重组、范围受限、显式冲突与
来源缺口。真实浏览器探针分别以 Enter、显式点击和 Escape 验证键盘/触控等价与焦点
归还；两个状态都只投影正式 Relation 和 EvidenceBinding，不创建独立事实。

### 6.3 HV-D03 Revision、Impact 与 Recovery 证据

```text
RevisionImpactArtifact = docs/design/high-fidelity/evidence/module-revision-impact-desktop.png
RevisionImpactArtifactState = revision-impact
RevisionImpactArtifactViewport = 1440x1100
RevisionImpactArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
RevisionImpactArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
RevisionImpactStateCode = REVISION_MODE+COMMIT_BLOCKED
RevisionImpactLaneCount = 3
RevisionImpactBlockerDefaultExpanded = YES
RevisionImpactCanonicalWrite = NONE
RecoveryArtifact = docs/design/high-fidelity/evidence/module-recovery-desktop.png
RecoveryArtifactState = partial-failure
RecoveryArtifactViewport = 1440x1100
RecoveryArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
RecoveryArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
RecoveryStateCode = CANONICAL_SAVED+PARTIAL_FAILURE
RecoveryCanonicalVersion = v13
RecoveryChangeSet = cs-1042
RecoveryProcessingStateCount = 4
ConflictedDraftArtifact = docs/design/high-fidelity/evidence/module-conflicted-draft-desktop.png
ConflictedDraftArtifactState = conflicted-draft
ConflictedDraftArtifactViewport = 1440x1100
ConflictedDraftArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
ConflictedDraftArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
ConflictedDraftStateCode = CONFLICTED_DRAFT+COMMIT_BLOCKED
```

修订证据同屏展示 Before/After 与 Semantic、Structural、Expression 三类影响，唯一
高风险 Blocker 默认展开且真实提交控件禁用。恢复主证据明确区分 `Canonical v13`
已经保存与后续重算/生成/核验的部分失败，旧投影保持可读但标记 `OUTDATED`；重试、
同幂等键结果查询和 Revert-as-new-ChangeSet 都是非生产确定性转换。冲突草稿补充证据
保留 Before/Latest/Draft 三方差异、草稿和原 Focus，在重新基线化前阻止提交。

### 6.4 HV-D04 跨层、小屏与静态导出证据

```text
LandscapeThemeArtifact = docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png
LandscapeThemeArtifactState = domain-default
LandscapeThemeArtifactViewport = 1440x1100
LandscapeThemeArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
LandscapeThemeArtifactFreshness = CHROME_RECAPTURE_BYTE_IDENTICAL
CrossDomainArtifact = docs/design/high-fidelity/evidence/cross-domain-reading-desktop.png
CrossDomainArtifactState = theme-default
CrossDomainArtifactViewport = 1440x1100
CrossDomainArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
SmallScreenArtifact = docs/design/high-fidelity/evidence/module-default-reading-small-screen.png
SmallScreenArtifactState = module-small-screen
SmallScreenArtifactViewport = 390x844
SmallScreenArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
SmallScreenPrimarySurface = DOCUMENT_FLOW
SmallScreenPersistentSidePanels = 0
StaticExportArtifact = docs/design/high-fidelity/evidence/static-export-example.png
StaticExportArtifactState = static-export
StaticExportArtifactViewport = 1200x1600
StaticExportArtifactStatus = CAPTURED_HIGH_FIDELITY_VISUAL
StaticExportManifest = docs/design/high-fidelity/evidence/static-export-manifest.json
StaticExportMachineIdentity = COMPANION_MANIFEST
StaticExportRawTechnicalIdsVisible = NO
StaticExportCanonicalAuthority = NONE
```

Landscape/Theme 主证据在同一阅读候选中保留唯一四层路径、领域结论、Theme 职责、
UnderstandingRoute 与 ThemeClosure，不退化为 Theme 目录、卡片墙或自由图谱。跨域补充
证据证明机制与规则/政策都只是 `CognitiveModule` 内容形态。小屏证据以单列连续文档、
44px 显式触控入口和临时全屏 overlay 保留阅读 Anchor；静态导出通过 companion JSON
使 Object、Relation 与来源身份机器可读，普通读者正文不显示技术 ID，图片不成为事实源。

## 7. 阶段边界

```text
HF-DG4 FixedDesignReview = PASS
HV-D00 VisualFoundation = PASS
HV-D01 ModuleDefaultReading = PASS
HV-D02 FocusAndSource = PASS
HV-D03 RevisionAndRecovery = PASS
HV-D04 CrossLayerResponsiveAndExport = PASS
HV-D05 FixedVisualUsabilityReview = NOT_RUN
```
