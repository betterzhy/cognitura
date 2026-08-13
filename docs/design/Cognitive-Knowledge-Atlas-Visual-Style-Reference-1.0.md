# Cognitive Knowledge Atlas Visual Style Reference 1.0

```text
CanonicalProjectName = Cognitura
HistoricalDocumentName = Cognitive-Knowledge-Atlas-Visual-Style-Reference
Version = 1.0
Status = FORMAL_VISUAL_STYLE_BASELINE
ActivationAuthority = docs/task-cards/visual-style-baseline/execution-state.md
ActivationGate = VSB-G0 GOVERNANCE_AND_REFERENCE
ReferencePath = docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
ReferenceRole = VISUAL_STYLE_REFERENCE_ONLY
SourceMediaType = image/jpeg
SourcePixelSize = 1280x853
SourceSizeBytes = 210103
SourceSHA256 = 812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249
ReferenceMediaType = image/png
ReferencePixelSize = 1280x853
ReferenceColorMode = RGB
ReferenceSizeBytes = 867083
ReferenceSHA256 = a8446ea987f6a1710c3845f837e2776190997b77f81584cf7b667cbfebe2f95f
PixelEquivalence = PASS
ConversionTool = Pillow 12.2.0
ConversionOperation = RGB_PNG_OPTIMIZE_FALSE_COMPRESS_LEVEL_6
PageArchitectureAuthority = NO
InteractionAuthority = NO
InformationArchitectureAuthority = NO
ComponentHierarchyAuthority = NO
CardQuantityAuthority = NO
DashboardLayoutAuthority = NO
```

本文只从批准的历史参考图提取视觉 DNA 与语义 token。图中的 dashboard 分区、导航、
卡片数量、工作流和控件层级均不是 Cognitura 的页面或交互权威。正式总体设计和高保真
交互专项拥有页面结构、Reading First、连续文档、状态、恢复与验收含义；当参考图与
正式设计冲突时，必须服从正式设计。

```text
FormalDesignPriority = FORMAL_DESIGN_OVERRIDES_VISUAL_REFERENCE
ReadingFirst = REQUIRED
PrimaryReadingSurface = CONTINUOUS_DOCUMENT
CardWall = FORBIDDEN
DashboardReplication = FORBIDDEN
GenericAISaaSStyling = FORBIDDEN
PixelMeasuredScope = COLOR_CLUSTER_ONLY
NonPixelExactClassification = INFERRED
```

## 1. 观察方法与置信度

参考图是经过 JPEG 编码的 1280×853 截图。颜色簇可从解码像素直接观察，因此用
`MEASURED_FROM_REFERENCE_PIXELS` 标识，并规范化为稳定的语义值。JPEG 压缩、抗锯齿、
缩放和未知显示链路使单个像素不能证明原始 CSS。字体身份、字号、字重、间距、圆角、
阴影、图标、控件高度、动效和密度均不能由截图像素精确恢复，只能标记为 `INFERRED`；
后续实现必须通过 VSB 卡的浏览器验证，而不能把推断写成已测事实。

## 2. 色彩观察与规范化

| Observation | Normalized | Confidence | Rationale |
|---|---|---|---|
| Canvas | `#F7F9FC` | `MEASURED_FROM_REFERENCE_PIXELS` | 大面积冷灰近白背景簇，区分页面画布和白色内容表面。 |
| PrimarySurface | `#FFF` | `MEASURED_FROM_REFERENCE_PIXELS` | 主内容区域最亮的白色簇。 |
| Secondary | `#FAFBFD` | `MEASURED_FROM_REFERENCE_PIXELS` | 次级容器的冷白簇。 |
| Tertiary | `#F5F7FA` | `MEASURED_FROM_REFERENCE_PIXELS` | 低权重分区和只读底色簇。 |
| BorderSubtle | `#E7EAF0` | `MEASURED_FROM_REFERENCE_PIXELS` | 大容器边界的最低对比灰蓝簇。 |
| Default | `#E2E6EC` | `MEASURED_FROM_REFERENCE_PIXELS` | 常规分隔线和控件边界簇。 |
| Strong | `#D4DAE3` | `MEASURED_FROM_REFERENCE_PIXELS` | 需要更清晰结构分组时的较强边界簇。 |
| TextPrimary | `#172033` | `MEASURED_FROM_REFERENCE_PIXELS` | 标题与关键正文的深蓝黑簇。 |
| TextSecondary | `#475467` | `MEASURED_FROM_REFERENCE_PIXELS` | 说明正文和次级标签的深灰蓝簇。 |
| Muted | `#667085` | `MEASURED_FROM_REFERENCE_PIXELS` | 元数据与低权重说明的中灰蓝簇。 |
| Subtle | `#98A2B3` | `MEASURED_FROM_REFERENCE_PIXELS` | 占位、禁用和辅助符号的浅灰蓝簇。 |
| Primary | `#4F67E8` | `MEASURED_FROM_REFERENCE_PIXELS` | 主操作、选中和关键路径的蓝紫色簇。 |
| Hover | `#455BDD` | `MEASURED_FROM_REFERENCE_PIXELS` | 主色加深后的悬停规范值。 |
| Active | `#3D50C9` | `MEASURED_FROM_REFERENCE_PIXELS` | 主色进一步加深后的按下规范值。 |
| Soft | `#EEF2FF` | `MEASURED_FROM_REFERENCE_PIXELS` | 选中项和轻量强调的淡蓝紫背景簇。 |
| Focus | `#7C6CF2` | `MEASURED_FROM_REFERENCE_PIXELS` | 聚焦对象和关系强调的紫色簇。 |
| FocusSoft | `#F3F0FF` | `MEASURED_FROM_REFERENCE_PIXELS` | 聚焦对象的低权重紫色背景簇。 |
| Success | `#278C68` | `MEASURED_FROM_REFERENCE_PIXELS` | 完成、有效和通过状态的绿色簇。 |
| SuccessSoft | `#ECF8F3` | `MEASURED_FROM_REFERENCE_PIXELS` | 成功状态的浅绿背景簇。 |
| Warning | `#C98526` | `MEASURED_FROM_REFERENCE_PIXELS` | 待处理、风险和需注意状态的琥珀色簇。 |
| WarningSoft | `#FFF6E5` | `MEASURED_FROM_REFERENCE_PIXELS` | 警告状态的浅琥珀背景簇。 |
| Danger | `#D64F58` | `MEASURED_FROM_REFERENCE_PIXELS` | 失败、阻断和破坏性状态的红色簇。 |
| DangerSoft | `#FFF0F1` | `MEASURED_FROM_REFERENCE_PIXELS` | 危险状态的浅红背景簇。 |
| Information | `#4385E0` | `MEASURED_FROM_REFERENCE_PIXELS` | 信息提示和非主路径链接的蓝色簇。 |
| InfoSoft | `#EEF6FF` | `MEASURED_FROM_REFERENCE_PIXELS` | 信息提示的浅蓝背景簇。 |

### 2.1 语义色使用预算

- Canvas 与 Surface 只建立阅读层次，不把每段内容包成独立卡片。
- Border 先使用 Subtle，只有键盘焦点、强边界或明确分组才提升对比度。
- Primary 只用于主要动作、选中路径和少量关键链接；Focus 专用于当前认知焦点或关系
  聚焦，不与 Primary 混为同一状态。
- Success、Warning、Danger、Information 必须同时附带文本或图形线索；颜色不能独立
  承担状态含义。Danger 只表示失败或阻断，不能表现普通未完成。
- 单一视口默认只保留一个主色高权重区域和一个当前焦点；多个语义色并置时降低背景
  饱和度，避免形成通用 AI SaaS 的彩色卡片墙。

## 3. 非像素精确推断

| Observation | Normalized | Confidence | Rationale |
|---|---|---|---|
| TypefaceIdentity | `SYSTEM_SANS_FOR_INTERFACE; FORMAL_READING_FONT_REMAINS_HF_AUTHORITY` | `INFERRED` | 截图可见中性无衬线界面气质，但像素不能确认字体文件；连续阅读字体仍服从正式 HF 设计。 |
| TypeScale | `12/14/16/20/24px_REFERENCE_RHYTHM_ONLY` | `INFERRED` | 可观察相对层级，不能从缩放截图证明 CSS 字号。 |
| FontWeight | `400/500/600_REFERENCE_RHYTHM_ONLY` | `INFERRED` | 正文、标签、标题有三级重量感，具体数值不可像素准确还原。 |
| SpacingScale | `4/8/12/16/24/32px_REFERENCE_RHYTHM_ONLY` | `INFERRED` | 界面呈四像素节奏，但截图不能证明布局盒模型。 |
| RadiusScale | `6/8/12px_REFERENCE_RHYTHM_ONLY` | `INFERRED` | 控件、轻量表面和较大容器呈小到中圆角，不能证明原始半径。 |
| ShadowStyle | `LOW_ELEVATION_COOL_NEUTRAL` | `INFERRED` | 主要依靠边框，仅有极轻阴影；阴影参数不可由 JPEG 精确恢复。 |
| IconStyle | `MONOLINE_ROUNDED_16_TO_20px` | `INFERRED` | 图标视觉上细线、圆角、低权重，具体图标库不构成权威。 |
| ControlHeight | `32_TO_40px_DESKTOP; 44px_MINIMUM_TARGET` | `INFERRED` | 截图呈紧凑桌面控件；正式可访问触达合同仍要求 44px。 |
| Motion | `120_TO_200ms_SUBTLE_FEEDBACK_ONLY` | `INFERRED` | 静态图没有动效证据，只允许保守过渡且尊重 reduced motion。 |
| Density | `COMPACT_INTERFACE; CALM_READING_SURFACE` | `INFERRED` | 参考图的工具区紧凑，但 Cognitura 正文必须保留连续阅读呼吸。 |
| Button | `PRIMARY_FILLED; SECONDARY_OUTLINED; TERTIARY_TEXT` | `INFERRED` | 由主次操作对比推断，不复制图中按钮数量或位置。 |
| Badge | `SOFT_BACKGROUND_PLUS_TEXT_OR_ICON` | `INFERRED` | 轻背景徽标适合状态附件，但不得以颜色独自传义。 |
| Relation | `FOCUS_PURPLE_WITH_THIN_DIRECTIONAL_CONNECTOR` | `INFERRED` | 蓝紫聚焦和细连接线可投影 Relation；关系语义与交互仍由正式设计定义。 |
| ReadingSurface | `WHITE_CONTINUOUS_DOCUMENT_ON_COOL_CANVAS` | `INFERRED` | 借用白表面与冷灰画布层次，不借用 dashboard 分栏。 |
| CardBudget | `NO_CARD_WALL; ONE_PRIMARY_VISUAL_PROJECTION_PER_SECTION` | `INFERRED` | 卡片外观只能包裹真正独立对象；连续解释不拆成瓷砖。 |
| SemanticColorBudget | `PRIMARY_PLUS_CURRENT_FOCUS; STATUS_ONLY_WHEN_MEANING_CHANGES` | `INFERRED` | 控制同时高权重色彩数量，保护 Reading First 的注意力顺序。 |

## 4. 投影规则

### 4.1 Canvas、Surface、Border 与 Text

桌面画布使用冷灰近白，连续阅读正文落在单一白色主表面。Secondary/Tertiary Surface
只服务于来源、状态或局部辅助说明，不能演变为常驻 dashboard 栏。BorderSubtle 用于
默认容器，Default 用于控件，Strong 只用于键盘焦点邻近结构或必须被识别的边界。
TextPrimary 承担标题与结论，TextSecondary 承担解释，Muted/Subtle 只承担元信息，
任何正文都不得通过低对比色换取“轻盈”。

### 4.2 Radius、Shadow、Spacing 与 Typography

圆角和阴影保持克制：阅读正文不悬浮，不对每个段落增加 elevation。间距按认知目的
分节，正文行长、衬线阅读字体与标题层级继续服从高保真视觉设计。参考图的紧凑工具
密度只可投影到局部控件，不得压缩 Continuous Document 的段落节奏。

### 4.3 Icon、Button 与 Badge

Icon 采用低权重单线语言并始终提供可访问名称。每个阅读状态的 Persistent Primary
Action 不得超过正式 HF 预算；Primary Button 只给当前主要动作，Secondary 和 Tertiary
逐级降权。Badge 只能作为附着于陈述的状态补充，并同时含可读文本或图标。

### 4.4 Relation 与 Reading Surface

Relation 使用 Focus/FocusSoft 与细方向线表达当前局部聚焦，但完整 Relation 陈述才是
稳定主焦点，起点和终点保持次级。Reading Surface 必须以 CoreQuestion、CoreConclusion、
连续解释、PrimaryCognitiveSpine、Conditions、Results、Boundaries/Exceptions 的顺序
服务阅读；来源和关系入口按需出现，不复制参考图的四象限或 dashboard 流程。

## 5. 禁止项与历史边界

- 禁止复刻参考图的 dashboard、四象限、侧栏、顶栏、统计面板或卡片数量。
- 禁止把蓝紫渐变、彩色徽标、密集卡片和“AI”装饰组合成通用 AI SaaS 外观。
- 禁止让视觉样式覆盖四层信息架构、Reading First、交互状态、恢复语义或 Canonical
  事实所有权。
- 禁止修改既有 HV 截图或历史 token 值来伪造新基线；历史证据保持对其固定候选有效。
- 禁止从 JPEG 的字体、阴影、圆角、布局或组件数量宣称像素级准确。

本基线只有在 execution-state 记录 `VSB-G0 GOVERNANCE_AND_REFERENCE` 通过且固定候选
完成独立审查后才可供 VSB-01 投影；本文落地本身不释放 VSB-01，不授权生产页面、
正式数据库写入或远程推送。
