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

本文只拥有批准参考图的 Visual DNA 与规范化语义 token。总体设计和正式高保真交互
专项继续拥有页面结构、Reading First、Continuous Document、状态、恢复和事实边界；
参考图中的 dashboard、导航、面板、卡片数量、工作流和组件层级均不获得权威。

```text
FormalDesignPriority = FORMAL_DESIGN_OVERRIDES_VISUAL_REFERENCE
ReadingFirst = REQUIRED
PrimaryReadingSurface = CONTINUOUS_DOCUMENT
CardWall = FORBIDDEN
DashboardReplication = FORBIDDEN
GenericAISaaSStyling = FORBIDDEN
PixelMeasuredScope = OBSERVED_PIXEL_CLUSTERS_ONLY
NormalizedTokenConfidence = INFERRED
NonPixelExactClassification = INFERRED
```

## 1. 观察、规范化与置信度

参考输入是压缩后的 1280×853 JPEG。Observation 只记录解码图像中实际出现的像素
cluster、范围或可见视觉现象；其 `MEASURED_FROM_REFERENCE_PIXELS` 置信度不传递给
Normalized semantic token。规范化 token 是为 Cognitura Reading First 产品做出的
正式选择，统一标记 `INFERRED`。字体、字号、字重、间距、圆角、阴影、图标、控件、
动效、密度和语义使用同样不能从 JPEG 精确恢复，均为 `INFERRED`。

## 2. 颜色 Observation 与规范化语义值

| Role | Reference observation | Normalized semantic token | Observation confidence | Normalization confidence | Rationale |
|---|---|---|---|---|---|
| CanvasBackground | `#F8F9FB`, `#F0F4F9` 附近的大面积冷灰画布像素簇 | `CanvasBackground = #F7F9FC` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 保留冷静背景层次，不复制 dashboard 分区。 |
| PrimarySurface | `#FEFEFE`, `#FFFFFF` 的主内容表面像素簇 | `PrimarySurface = #FFFFFF` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 为连续阅读提供最高亮度表面。 |
| SecondarySurface | `#F9FAFC`, `#FAFBFD` 的冷白次级表面像素簇 | `SecondarySurface = #FAFBFD` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 只服务局部投影或辅助分组。 |
| TertiarySurface | `#F7F8FA`, `#F8F9FB` 的低权重表面像素簇 | `TertiarySurface = #F5F7FA` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 用于轻量 band，不制造嵌套卡片。 |
| BorderSubtle | `#E3E5EC` 附近的最浅容器边界像素簇 | `BorderSubtle = #E7EAF0` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 让默认分隔低于正文。 |
| BorderDefault | `#E3E5EC` 附近的常规控件边界像素簇 | `BorderDefault = #E2E6EC` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 保持控件可辨而不加重页面。 |
| BorderStrong | `#D4D8E2` 附近的强调边界像素簇 | `BorderStrong = #D4DAE3` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 仅用于必须识别的结构或状态。 |
| TextPrimary | `#1E1D21`, `#31333A` 附近的标题深色像素簇 | `TextPrimary = #172033` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 建立结论和正文标题的稳定对比。 |
| TextSecondary | `#31333A`, `#475467` 附近的说明文字像素簇 | `TextSecondary = #475467` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 承担连续解释和次级标签。 |
| TextMuted | `#667085` 附近的元信息灰蓝像素簇 | `TextMuted = #667085` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 只用于不改变核心理解的元信息。 |
| TextSubtle | `#98A2B3` 附近的低权重文字像素簇 | `TextSubtle = #98A2B3` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 限于占位、禁用和辅助符号。 |
| PrimaryColor | `#3263D9`, `#335AD7` 附近的主蓝像素簇 | `PrimaryColor = #4F67E8` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 作为默认阅读视图唯一高强度颜色。 |
| PrimaryHover | 主蓝控件的可见加深像素簇 | `PrimaryHover = #455BDD` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 提供克制的 hover 反馈。 |
| PrimaryActive | 主蓝控件的最深交互像素簇 | `PrimaryActive = #3D50C9` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 区分按下状态而不引入渐变。 |
| PrimarySoft | 选中项的浅蓝紫背景像素簇 | `PrimarySoft = #EEF2FF` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 以软填充表达 selected。 |
| FocusColor | `#7F5CDE`, `#A078ED` 附近的认知紫像素簇 | `FocusColor = #7C6CF2` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | Purple 只标记当前认知焦点。 |
| FocusSoft | 认知焦点周围的浅紫背景像素簇 | `FocusSoft = #F3F0FF` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 聚焦背景低于完整 Relation 陈述。 |
| Success | 确认与完成标记中的低面积绿色像素簇 | `Success = #278C68` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | Green 只表示成功或确认。 |
| SuccessSoft | 成功标记周围的浅绿背景像素簇 | `SuccessSoft = #ECF8F3` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 状态背景保持低饱和。 |
| Warning | 风险与注意标记中的低面积琥珀像素簇 | `Warning = #C98526` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | Amber 只表示边界、风险或注意。 |
| WarningSoft | 注意标记周围的浅琥珀背景像素簇 | `WarningSoft = #FFF6E5` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 不与普通未完成混用。 |
| Danger | 冲突与错误标记中的低面积红色像素簇 | `Danger = #D64F58` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | Red 只表示冲突、错误或高风险。 |
| DangerSoft | 错误标记周围的浅红背景像素簇 | `DangerSoft = #FFF0F1` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 保护错误文字可读性。 |
| Information | 信息入口和辅助链接中的蓝色像素簇 | `Information = #4385E0` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 只表示信息，不冒充 Primary Action。 |
| InformationSoft | 信息入口周围的浅蓝背景像素簇 | `InformationSoft = #EEF6FF` | `MEASURED_FROM_REFERENCE_PIXELS` | `INFERRED` | 维持信息提示的低权重。 |

## 3. Typography 合同

完整无网络 Sans fallback stack 为：

```css
font-family:
  Inter,
  "PingFang SC",
  "SF Pro Text",
  "Noto Sans SC",
  "Microsoft YaHei",
  system-ui,
  -apple-system,
  BlinkMacSystemFont,
  "Segoe UI",
  sans-serif;
```

Inter 未安装时自然回退；不得新增远程字体请求或大型字体包。

| Role | Reference observation | Normalized contract | Confidence | Rationale |
|---|---|---|---|---|
| FontStack | 静态截图只能观察中性 Sans 气质，无法识别字体文件 | `Inter, PingFang SC, SF Pro Text, Noto Sans SC, Microsoft YaHei, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif` | `INFERRED` | 完整 fallback 避免外部网络依赖。 |
| DisplayPageTitle | 可见最高标题层级 | `32px / 40px / 700` | `INFERRED` | 对应 Page Title / Display。 |
| H1ObjectTitle | 可见对象标题层级 | `28px / 36px / 600` | `INFERRED` | 对应 Object Title / H1。 |
| H2MajorSection | 可见主要章节层级 | `22px / 30px / 600` | `INFERRED` | 对应 Major Section / H2。 |
| H3CognitiveSection | 可见认知小节层级 | `18px / 26px / 600` | `INFERRED` | 对应 Cognitive Section / H3。 |
| Body16 | 截图正文比例可见但无法恢复 CSS 数值 | `16px / 27px / 400; line-height ratio 1.6875 within 1.65..1.75` | `INFERRED` | 连续阅读不得退回 13–14px dashboard 正文。 |
| UI14 | 紧凑控件和标签层级 | `14px / 21px / 400 or 500` | `INFERRED` | 只用于界面标签。 |
| Metadata13 | 低权重元信息层级 | `13px / 18px / 400 or 500` | `INFERRED` | 不承担核心解释。 |
| Caption12 | 最小辅助说明层级 | `12px / 18px / 400 or 500` | `INFERRED` | 保持辅助文本可读。 |
| FontWeights | 图像可见四级层次但不能证明数值 | `400,500,600,700 only` | `INFERRED` | 禁止任意增加权重等级。 |

## 4. Spacing、Width、Radius 与 Shadow 合同

| Role | Reference observation | Normalized contract | Confidence | Rationale |
|---|---|---|---|---|
| SpacingScale | 可观察四像素节奏，无法恢复盒模型 | `4,8,12,16,20,24,32,40,48,64px` | `INFERRED` | 覆盖紧凑控件到阅读章节。 |
| SectionSpacingRules | 组间距与章节留白呈清晰递增 | `icon 6..8; compact 12; component 16; related 24; major 32..40; chapter 48..64px` | `INFERRED` | 用留白建立认知层级。 |
| ReadingWidths | 图像宽度不能证明正式 viewport | `ReadingColumn 720..860px; Projection 900..1100px; Application 1280..1440px` | `INFERRED` | 正文、投影和应用宽度分别受限。 |
| RadiusScale | 可见小到中圆角和 pill | `6,8,10,12,16,999px` | `INFERRED` | 不允许统一大圆角。 |
| RadiusUsage | 控件和语义表面半径可见但不可精确恢复 | `Input/Button 8; SemanticBox 8..10; Projection 12; Workspace 12..16; Badge pill` | `INFERRED` | 半径随真实语义边界变化。 |
| ShadowXs | 极轻边缘深度可见 | `0 1px 2px rgb(16 24 40 / 4%)` | `INFERRED` | 仅作为 bounded projection 上限。 |
| ShadowSm | 静态图无法证明 popover 阴影参数 | `0 2px 6px rgb(16 24 40 / 5%)` | `INFERRED` | 只允许 Popover 或 Floating Focus。 |
| ShadowMd | 静态图无法证明较高浮层参数 | `0 6px 18px rgb(16 24 40 / 7%)` | `INFERRED` | 只允许必要的临时高浮层。 |

```text
SpacingBase = 4px
RadiusUnifiedLarge = FORBIDDEN
ReadingSurfaceShadow = NONE
PopoverShadow = SHADOW_SM_OR_MD_ONLY
```

## 5. Icon、Button、Badge、Focus 与 Motion

| Role | Reference observation | Normalized contract | Confidence | Rationale |
|---|---|---|---|---|
| IconRules | 可见单线、低权重图标，不能识别库 | `first slice adds no library; future uses one Outline library only; 16/18/20/24px; stroke 1.5..1.75` | `INFERRED` | 禁止混合图标体系。 |
| PrimaryButton | 可见蓝底白字主动作 | `primary blue fill; white text; radius 8px; no gradient; no large shadow` | `INFERRED` | 每页主动作服从正式预算。 |
| SecondaryButton | 可见低权重边框动作 | `white or transparent; subtle border; dark text` | `INFERRED` | 不与 Primary 争夺注意力。 |
| TertiaryButton | 可见纯文字或图标动作 | `transparent; no border; text or icon` | `INFERRED` | 只承载最低权重动作。 |
| BadgeRules | 可见软背景紧凑状态标记 | `soft background; semantic text; compact padding; status only; pill` | `INFERRED` | 颜色不能成为唯一状态信号。 |
| FocusRing | 静态图无法证明键盘焦点 CSS | `2px solid rgb(79 103 232 / 32%); offset 2px` | `INFERRED` | 所有可交互入口保留 focus-visible。 |
| MotionRules | JPEG 不含时间轴证据 | `120..180ms ease-out; Hover, Focus, Popover, Disclosure, local Relation Expansion only` | `INFERRED` | 禁止装饰性大范围动画。 |
| DensityRules | 工具区紧凑、阅读区留白的视觉对比 | `compact controls; calm continuous reading surface` | `INFERRED` | dashboard 密度不得进入正文。 |

Selected 只使用软填充加语义边框；Hover 只做轻微背景变化。状态必须同时拥有文字或
图形线索，不能只靠颜色。

## 6. Relation 视觉语言

| Role | Reference observation | Normalized contract | Confidence | Rationale |
|---|---|---|---|---|
| RelationRecognitionPriority | 图中关系同时使用文字、形状、方向和线 | `Natural Language Statement > Relation Verb > Shape > Direction > Endpoint > Line Style > Color` | `INFERRED` | 颜色永远不是首要关系信号。 |
| RelationLine | 可见细连接线 | `1..1.5px` | `INFERRED` | 控制视觉噪声。 |
| RelationFocused | 可见当前关系对比提升 | `solid; higher contrast; explicit arrow; visible Relation Verb` | `INFERRED` | 完整 Relation 陈述是稳定主焦点。 |
| RelationWeak | 可见次级关系降低权重 | `dashed; lower contrast` | `INFERRED` | 仍需文字语义。 |
| RelationNonFocused | 非当前关系细节弱化 | `reduce detail and contrast` | `INFERRED` | 避免蜘蛛网和密集交叉。 |

禁止装饰曲线、彩虹线、蜘蛛网、密集交叉或仅以颜色区分 Relation 类型。

## 7. Reading Surface 与 Card Budget

正式主序保持：

```text
Module Identity
→ Core Question
→ Core Conclusion / Explanation
→ Primary Cognitive Spine
→ Mechanism / Rule / Structure Projection
→ Continuous Explanation
→ Boundary / Exception
→ Knowledge Elements
→ Local Relations
→ Source Entry
```

`DOC-GAP-MDR-001` 继续阻断 Conditions/Results 的完整 Canonical 映射。正式投影不得
新增独立 Conditions/Results 区段，也不得从现有字段推断；如 Visual Reference 为检查
形式展示标签，必须标记 `SYNTHETIC_VISUAL_REFERENCE_ONLY`，且不得导入生产组件。

```text
ConditionsResultsFormalProjection = BLOCKED_BY_DOC-GAP-MDR-001
ConditionsResultsSyntheticInference = FORBIDDEN
Card = SEMANTIC_BOUNDARY_NOT_DEFAULT_LAYOUT_PRIMITIVE
PrimaryVisualProjectionPerCognitiveSection <= 1
DefaultReadingPersistentSidePanels = 0
DefaultReadingPermanentToolbars = 0
DefaultReadingPersistentPrimaryActionsPerPage <= 2
```

| Role | Reference observation | Normalized contract | Confidence | Rationale |
|---|---|---|---|---|
| ReadingSurfaceRules | 参考图存在白表面与冷灰画布层次 | `white continuous document; no shadow; ReadingColumn 720..860px` | `INFERRED` | 不继承四象限和常驻 dashboard 面板。 |
| VisualHierarchy | 可见留白、文字、对齐、分隔和背景递进 | `Whitespace > Typography > Alignment > Divider > Background Band > Semantic Surface > Card` | `INFERRED` | Card 是最后手段。 |
| CardBudget | 图中大量卡片只作为反向结构证据 | `semantic boundary only; no nested cards; no same-shape card wall; primary projection <= 1` | `INFERRED` | 普通定义、解释、结论和关系陈述不包卡。 |
| SemanticColorBudget | 图中蓝、紫和状态色具有不同权重 | `Primary Blue only high intensity; Purple focus only; Green success; Amber boundary/risk; Red conflict/error; unrelated states neutral` | `INFERRED` | 同屏不得高强度展示全部语义色。 |

只有机制投影、边界/例外、局部 Relation Focus、Source Evidence 或 Revision Workspace
等真实语义边界可成为 Surface。

## 8. 禁止项与阶段边界

```text
DashboardLikePanorama = FORBIDDEN
ThemeCardWall = FORBIDDEN
CardWallAsPrimaryReading = FORBIDDEN
PermanentRightSideRelationshipPanel = FORBIDDEN
RelationshipOnlyGraphPage = FORBIDDEN
EverythingInsideCards = FORBIDDEN
NestedCards = FORBIDDEN
GlobalGovernanceDashboardInReadingMode = FORBIDDEN
DenseAlwaysVisibleControls = FORBIDDEN
GlobalFreeKnowledgeGraph = FORBIDDEN
InfiniteCanvas = FORBIDDEN
GenericAISaaSStyling = FORBIDDEN
```

禁止通过蓝紫渐变、彩色徽标、密集卡片和“AI”装饰形成通用 AI SaaS 外观。禁止修改
既有 HV 截图或历史 token 来伪造新基线；历史证据继续对其固定候选有效。只有
execution-state 记录 `VSB-G0 GOVERNANCE_AND_REFERENCE` 通过且固定候选完成独立审查
后，本文才可供 VSB-01 消费；文档落地本身不释放 VSB-01，不授权生产页面、正式数据库
写入或远程推送。
