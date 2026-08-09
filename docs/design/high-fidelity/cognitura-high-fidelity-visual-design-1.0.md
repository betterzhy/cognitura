# Cognitura 高保真视觉设计 1.0

```text
CanonicalProjectName = Cognitura
DesignKind = HIGH_FIDELITY_VISUAL_DESIGN
DesignStatus = VISUAL_FOUNDATION_ESTABLISHED
ContractSource = Cognitura-High-Fidelity-Interaction-Specialty-1.0
ContractGate = HF-DG4 PASS
FoundationGate = HV-D00 PASS
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
`HV-D00` 只建立 token、响应式阈值、fixture 治理和基础截图；默认 Module、Relation、
SourceEvidence、Revision、Recovery、跨层、小屏与导出的真实视觉验收仍由
`HV-D01..D04` 逐卡完成，最终可用性由 `HV-D05` 固定候选审查。

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

## 7. 阶段边界

```text
HF-DG4 FixedDesignReview = PASS
HV-D00 VisualFoundation = PASS
HV-D01 ModuleDefaultReading = NOT_RUN
HV-D02 FocusAndSource = NOT_RUN
HV-D03 RevisionAndRecovery = NOT_RUN
HV-D04 CrossLayerResponsiveAndExport = NOT_RUN
HV-D05 FixedVisualUsabilityReview = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
```
