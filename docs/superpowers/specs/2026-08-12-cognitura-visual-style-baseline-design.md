# Cognitura Visual Style Baseline Design

```text
CanonicalProjectName = Cognitura
DesignKind = VISUAL_STYLE_BASELINE_REESTABLISHMENT
DesignDate = 2026-08-12
DesignApproval = USER_APPROVED_IN_THREE_SECTIONS
DevelopmentBranch = codex/high-fidelity-design-integration
FrozenWave1TaskCard = W1-I03
FrozenWave1CandidateSHA = 4e63936c631ab34807e714b90d30415a959bc13d
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

## 1. 目标

本设计建立新的正式 Web Visual Style Baseline。它从历史参考图提取视觉语言，
再把该语言投影到当前正式 Reading First 产品设计和现有有限
`ModuleDefaultReading` 组件，而不是复制参考图的 Dashboard 页面结构。

本轮目标同时包含：

1. 受控登记参考图及其来源指纹；
2. 形成正式 Visual Style Reference；
3. 建立唯一生产语义 Token 投影；
4. 重塑现有 `ModuleDefaultReading` 有限组件的视觉表达；
5. 建立独立 Vite Visual Reference；
6. 生成三档桌面截图、Reference Comparison 和可复现验收报告。

本轮不接入 App Shell、产品路由、HTTP、后端、持久化或 Schema，不生成完整产品
页面，不写正式数据库，不远程 Push。

## 2. 当前 Repository 事实

### 2.1 分支与冻结边界

工作在现有分支：

```text
Branch = codex/high-fidelity-design-integration
StartingHEAD = 4e63936c631ab34807e714b90d30415a959bc13d
UntrackedUserState = .idea/
```

`W1-I03` 的当前候选固定在上述 SHA。本视觉工作流不得修改该候选的
`server/src/main/java/io/cognitura/source/docx/security/**`、对应测试或 fixture。
`.idea/` 必须继续保持未跟踪并排除在所有提交之外。

Visual Style Baseline bootstrap 必须为 Wave 1 implementation 状态机增加可验证的
用户暂停语义：

```text
Wave1TaskCardSetStatus = SUSPENDED_BY_USER
Wave1ActiveTaskCard = NONE
Wave1SuspendedTaskCard = W1-I03
Wave1SuspendedCandidateSHA = 4e63936c631ab34807e714b90d30415a959bc13d
Wave1SuspendedCandidateMutation = FORBIDDEN
```

暂停状态必须由 Wave 1 task-card validator 的正反例覆盖。Visual Style Baseline
达到最终 GO 后，或用户明确停止本工作流后，才允许用独立状态提交把 `W1-I03`
恢复为唯一 `READY`；恢复不能改写或 amend 固定候选。

### 2.2 正式 Authority Chain

视觉工作消费以下当前可核验权威：

1. `cognitive-knowledge-atlas-overall-design-1.2.md`：产品定位、四层结构、页面与
   Renderer 上位权威；
2. `Cognitive-Knowledge-Atlas-Interaction-State-Completion-and-High-Fidelity-Input-Design-1.0.md`：
   Reading First、Interactive Cognitive Document、连续叙事、交互状态、关系表达、
   Card/Container 与交互暴露预算；
3. `docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md`：既有
   Reading First 构图和历史 HV 证据合同；
4. 本轮新建的 `docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md`：
   新的 Visual DNA 和语义视觉 Token 权威；
5. `web/src/styles/**`：上述正式视觉 Token 的生产 CSS 投影，不拥有独立设计裁决。

仓库不存在以下三份历史正文：

```text
DOC-GAP-HF-001 = Cognitive-Knowledge-Atlas-Cognitive-Relationship-and-Page-Structure-Design-1.0
DOC-GAP-HF-002 = Cognitive-Knowledge-Atlas-Cognitive-Relationship-Expression-and-Interaction-Design-1.0
DOC-GAP-HF-003 = Cognitive-Knowledge-Atlas-Interaction-State-and-Multi-View-Consistency-Design-1.0
```

不得伪称已读取这些缺失正文。关系、页面和交互规则只从 Overall 已回迁内容及当前
正式高保真交互专项取得。

### 2.3 既有视觉与生产实现状态

- 既有 `docs/design/high-fidelity/prototype/**` 是 docs-only、确定性、非生产 fixture；
- 既有 `docs/design/high-fidelity/evidence/**` 是历史 HV-D00..D05 验收证据，不得覆盖；
- 现有生产 `ModuleDefaultReading` 已投影八段连续阅读顺序、一个 Stage Chain 主投影、
  一至三条 Relation 和按需 Source Entry；
- `App.tsx` 仍是空 Application Shell，本轮不修改；
- `DOC-GAP-MDR-001` 继续阻断 Conditions/Results 的完整 Canonical 映射，视觉工作不得
  通过 CSS、fixture 或组件命名反向制造正式字段。

## 3. 参考图登记与逆向边界

### 3.1 来源

用户提供的实际附件为：

```text
SourceMediaType = image/jpeg
SourcePixelSize = 1280x853
SourceSizeBytes = 210103
SourceSHA256 = 812eb50de5b4c7678349bf427977d2917388b70f25f18b6035f55123c7739249
```

实施时必须把相同像素内容无裁剪、无重绘地转码并登记到：

```text
RepositoryReferencePath = docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
ReferenceRole = VISUAL_STYLE_REFERENCE_ONLY
```

正式文档必须同时记录源 JPEG SHA-256、仓库 PNG SHA-256、像素尺寸、转换命令和
无裁剪/无缩放校验。若临时附件不存在、源 SHA 不匹配或转换后像素改变，Gate 失败，
不得用近似重制图替代。

### 3.2 参考图拥有的权威

```text
VisualStyleReference =
  COLORS
  + TYPOGRAPHY_CHARACTER
  + SPACING_RHYTHM
  + SURFACE_TREATMENT
  + BORDER_TREATMENT
  + SHADOW_CHARACTER
  + ICON_CHARACTER
  + CONTROL_CHARACTER
  + INFORMATION_DENSITY_FEEL
  + SEMANTIC_COLOR_FEEL
```

### 3.3 参考图不拥有的权威

```text
PageArchitectureAuthority = NO
InteractionAuthority = NO
InformationArchitectureAuthority = NO
ComponentHierarchyAuthority = NO
CardQuantityAuthority = NO
DashboardLayoutAuthority = NO
```

以下参考图结构不得继承：

```text
DashboardLikePanorama
ThemeCardWall
CardWallAsPrimaryReading
PermanentRightSideRelationshipPanel
RelationshipOnlyGraphPage
EverythingInsideCards
PanelInsidePanelInsidePanel
GlobalGovernanceDashboardInReadingMode
DenseAlwaysVisibleControls
GlobalFreeKnowledgeGraph
InfiniteCanvas
```

## 4. Visual DNA 逆向结果

### 4.1 观察与规范化原则

参考图是压缩后的四屏合成 JPEG。颜色可以通过实际像素聚类和局部取样记录为
`MEASURED_FROM_REFERENCE_PIXELS`；字体家族、字重、字号、间距、圆角、阴影和图标
笔画无法从该文件精确恢复，必须标记为 `INFERRED`。

正式 Visual Style Reference 必须并列记录：

- Reference observation：图像中实际观测的范围或代表色；
- Normalized semantic token：为当前 Reading First 产品规范化后的正式值；
- Confidence：`MEASURED_FROM_REFERENCE_PIXELS` 或 `INFERRED`；
- Rationale：为何该值属于同一产品家族且不复制旧结构。

不得把 JPEG 压缩产生的偶然像素当成精确设计值。

### 4.2 实际颜色观察

像素聚类与局部取样得到的代表范围：

| 角色 | 参考图观察 | 证据类型 |
|---|---|---|
| Canvas | `#F8F9FB`, `#F0F4F9` 附近 | `MEASURED_FROM_REFERENCE_PIXELS` |
| Primary Surface | `#FEFEFE`, `#FFFFFF` | `MEASURED_FROM_REFERENCE_PIXELS` |
| Border | `#E3E5EC` 附近 | `MEASURED_FROM_REFERENCE_PIXELS` |
| Dark text | `#1E1D21`, `#31333A` 附近 | `MEASURED_FROM_REFERENCE_PIXELS` |
| Primary blue | `#3263D9`, `#335AD7` 附近 | `MEASURED_FROM_REFERENCE_PIXELS` |
| Cognitive purple | `#7F5CDE`, `#A078ED` 附近 | `MEASURED_FROM_REFERENCE_PIXELS` |

### 4.3 规范化语义色

正式基线采用以下初始值：

```css
--color-canvas: #F7F9FC;
--surface-reading: #FFFFFF;
--surface-projection: #FAFBFD;
--surface-subtle: #F5F7FA;
--border-subtle: #E7EAF0;
--border-default: #E2E6EC;
--border-strong: #D4DAE3;
--text-primary: #172033;
--text-secondary: #475467;
--text-muted: #667085;
--text-subtle: #98A2B3;
--color-primary: #4F67E8;
--color-primary-hover: #455BDD;
--color-primary-active: #3D50C9;
--color-primary-soft: #EEF2FF;
--color-focus: #7C6CF2;
--color-focus-soft: #F3F0FF;
--color-success: #278C68;
--color-success-soft: #ECF8F3;
--color-warning: #C98526;
--color-warning-soft: #FFF6E5;
--color-danger: #D64F58;
--color-danger-soft: #FFF0F1;
--color-info: #4385E0;
--color-info-soft: #EEF6FF;
```

这些是语义 Token。禁止生产组件创建 `--blue-*`、`--purple-card`、`--green-box`
等视觉实现名作为第二套权威。

### 4.4 Typography

使用一个无外部网络依赖的 Sans 栈：

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

Inter 未安装时自然回退；本轮不新增大型字体包或远程字体请求。正式比例为：

| Role | Size / Line Height | Weight | Confidence |
|---|---|---:|---|
| Page Title | `32px / 40px` | `700` | `INFERRED` |
| Object Title | `28px / 36px` | `600` | `INFERRED` |
| Major Section | `22px / 30px` | `600` | `INFERRED` |
| Cognitive Section | `18px / 26px` | `600` | `INFERRED` |
| Reading Body | `16px / 27px` | `400` | `INFERRED` |
| Compact UI | `14px / 21px` | `400` or `500` | `INFERRED` |
| Metadata | `13px / 18px` | `400` or `500` | `INFERRED` |
| Caption | `12px / 18px` | `400` or `500` | `INFERRED` |

只允许 `400/500/600/700`。Reading Body 不得退回 Dashboard 常见的 13–14px。

### 4.5 Spacing、宽度、圆角和阴影

```text
SpacingBase = 4px
SpacingScale = 4,8,12,16,20,24,32,40,48,64
ReadingColumn = 720px..860px
ProjectionWidth = 900px..1100px
ApplicationMaxWidth = 1280px..1440px
RadiusScale = 6px,8px,10px,12px,16px,999px
```

默认组件规则：

- Inline icon gap：`6–8px`；
- Compact group：`12px`；
- Normal component：`16px`；
- Related section：`24px`；
- Major section：`32–40px`；
- Reading chapter：`48–64px`；
- Input/Button：`8px`；
- Semantic box：`8–10px`；
- Bounded projection：`12px`；
- Large workspace：`12–16px`；
- Badge：pill。

阴影只允许：

```css
--shadow-xs: 0 1px 2px rgb(16 24 40 / 4%);
--shadow-sm: 0 2px 6px rgb(16 24 40 / 5%);
--shadow-md: 0 6px 18px rgb(16 24 40 / 7%);
```

默认 Reading Surface 为无阴影。Popover 或 Floating Focus 才可使用 `sm/md`。

## 5. Reading First 视觉投影规则

### 5.1 页面主序

正式骨架保持：

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

`DOC-GAP-MDR-001` 下，生产组件不增加独立 Conditions/Results 区段。Visual Reference
若为了检查完整形式展示这些标签，必须标为 `SYNTHETIC_VISUAL_REFERENCE_ONLY`，并且
不能被生产组件或 Canonical projection 导入。

### 5.2 Surface 与 Card Budget

```text
Card = SEMANTIC_BOUNDARY_NOT_DEFAULT_LAYOUT_PRIMITIVE
PrimaryVisualProjectionPerCognitiveSection <= 1
DefaultReadingPersistentSidePanels = 0
DefaultReadingPermanentToolbars = 0
DefaultReadingPersistentPrimaryActionsPerPage <= 2
```

视觉层级优先级为：

```text
Whitespace
→ Typography
→ Alignment
→ Divider
→ Background Band
→ Semantic Surface
→ Card
```

主 Reading Surface 无阴影。普通定义、解释、结论和关系陈述不包卡；只有机制投影、
边界/例外、局部 Relation Focus、Source Evidence 或 Revision Workspace 等真实语义
边界可成为 Surface。禁止嵌套 Card 和同形 Card Wall。

### 5.3 Relation 视觉语言

关系识别顺序必须是：

```text
Natural Language Statement
→ Relation Verb
→ Shape
→ Direction
→ Endpoint
→ Line Style
→ Color
```

默认关系线 `1–1.5px`。聚焦关系使用 solid、较高对比、明确箭头和可见 Relation
Verb；弱关系可使用 dashed 和较低对比；非聚焦关系降低细节。颜色不能成为唯一类型
信号，不构造蜘蛛网、装饰曲线、彩虹线或密集交叉。

### 5.4 Interaction、Icon 与 Motion

- Primary Button：主蓝填充、白字、8px 圆角、无渐变、无大阴影；
- Secondary Button：白色或透明、轻边框、深色文字；
- Tertiary Button：透明、无边框、文字或图标；
- Badge：软背景、语义文字、紧凑 padding，只表达状态；
- 首个切片不新增 Icon Library；使用文字语义及克制的 CSS/SVG 方向标记；
- 若后续选择图标库，只能选择一个 Outline 体系，尺寸 16/18/20/24px，stroke
  `1.5–1.75`；
- Hover 只做轻微背景变化；Selected 使用软填充加语义边框；
- Focus Ring 为 `2px solid rgb(79 103 232 / 32%)`，offset `2px`；
- Motion 只允许 `120–180ms ease-out` 的 Hover、Focus、Popover、Disclosure 和局部
  Relation Expansion。

### 5.5 Semantic Color Budget

默认 Reading View 以 Primary Blue 为唯一高强度颜色。Purple 只标记当前认知焦点；
Green 只表示成功/确认；Amber 只表示边界、风险或注意；Red 只表示冲突、错误或高风险。
不相关状态必须降为 Neutral，同屏不得高强度展示全部语义色。

## 6. 单一视觉权威桥接

选定方案为：

```text
Formal Visual Style Reference
→ Semantic CSS Tokens
→ Production ModuleDefaultReading
→ Independent Vite Visual Reference
```

拒绝的替代方案：

1. 只修改 docs-only 原型：不能验证生产组件；
2. 同时实现 App Shell、Sidebar、Top Navigation：越过当前有限页面边界并增加
   Dashboard 回归风险。

### 6.1 正式文档职责

`docs/design/Cognitive-Knowledge-Atlas-Visual-Style-Reference-1.0.md` 是完成 Gate 后的
`FORMAL_VISUAL_STYLE_BASELINE`。它至少记录：

```text
CanvasBackground
PrimarySurface
SecondarySurface
Border
TextPrimary
TextSecondary
TextMuted
PrimaryColor
PrimarySoft
FocusColor
Success
Warning
Danger
RadiusScale
ShadowScale
SpacingScale
TypographyScale
IconRules
ButtonRules
BadgeRules
RelationRules
ReadingSurfaceRules
```

`docs/design/high-fidelity/cognitura-high-fidelity-visual-design-1.0.md` 继续拥有 Reading
First 构图和历史 HV 证据事实，但它的旧暖色/Serif prototype token 不再是新生产实现
权威。实施时必须显式链接新的 Style Reference，并把旧 prototype 值标记为
`HISTORICAL_EVIDENCE_RENDERING_ONLY`。历史截图不因新基线而改写或失效。

### 6.2 生产 CSS 职责

计划文件：

```text
web/src/styles/tokens.css
web/src/styles/typography.css
web/src/styles/surfaces.css
web/src/styles/cognitive-visual.css
web/src/styles/cognitura.css
```

- `tokens.css`：唯一语义变量声明；
- `typography.css`：字体栈、字号、字重和阅读行高角色；
- `surfaces.css`：Canvas、Reading Surface、Projection、Border、Radius 和 Shadow；
- `cognitive-visual.css`：Relation、状态、Focus 和认知投影视觉规则；
- `cognitura.css`：只负责本地 import，不声明第二套值。

组件 CSS 必须消费这些 Token。除正式 Style Reference 明确列出的基础值外，禁止在
组件 CSS 中新增未经批准的硬编码色值。

### 6.3 Production ModuleDefaultReading

本轮只允许调整现有 `web/src/modules/module-reading/**` 的呈现标记、可访问标签、
视觉 class 和 CSS。必须保留：

- 八段 Canonical DOM 顺序；
- 一个主视觉投影；
- 一至三条 Formal Relation；
- Source Entry 按需出现；
- 零 `complementary` 常驻侧栏；
- Canonical Relation identity/type/source/target 的 fail-closed 检查；
- Conditions/Results 不从现有字段推断。

不得修改 `App.tsx`，不得将 Visual Reference fixture 数据导入生产组件。

### 6.4 Vite Visual Reference

建立独立入口而不是 Storybook 依赖：

```text
web/visual-reference.html
web/src/visual-reference/main.tsx
web/src/visual-reference/VisualReference.tsx
web/src/visual-reference/module-default-reading.fixture.ts
web/src/visual-reference/visual-reference.css
```

Vite 必须把该入口纳入 build。fixture 数据为确定性、离线、无用户数据的 Visual
Reference；不得访问 `raw/**`、网络、Cookie、localStorage、sessionStorage、HTTP、
后端或数据库。Visual Reference 必须明显标注自身不是产品路由，也不拥有 Canonical
事实。

## 7. 数据流与失败关闭

唯一数据流：

```text
Formal Design
→ Visual Style Reference
→ Semantic CSS Tokens
→ ModuleDefaultReading
→ Deterministic Visual Reference
→ Evaluated DOM + Screenshots
→ Visual Acceptance Report
```

以下任一情况必须失败：

1. 参考源 SHA、路径、尺寸或转码像素不符；
2. 必需语义 Token 缺失、重复或 CSS 出现平行主题值；
3. 组件 DOM 缺少正式阅读段、删除/复制/重排段落；
4. 产生常驻右侧面板、Dashboard、Card Wall 或超过一个主投影；
5. Relation 数量不在 1–3，或 identity/type/source/target 漂移；
6. Source Entry 不可聚焦、默认展开或泄露机器 source ID；
7. 生产组件推断 Conditions/Results；
8. Visual Reference 使用网络、持久化或 `raw/**`；
9. computed style 与正式 Token 不符；
10. 截图不是由当前候选 DOM/CSS 重新捕获；
11. 任何历史 HV 证据被覆盖；
12. `W1-I03@4e63936` 固定候选发生变化。

验证器必须检查真实 evaluated DOM 和 Chrome computed style，不得用自报 `data-*`
计数替代实际节点、布局和样式观察。

## 8. 任务卡与 Gate

先执行一次不含产品交付的治理 bootstrap，再释放四张严格串行卡。bootstrap 由本设计
和用户已给出的集合级授权直接约束；它不能由尚未存在的 `VSB-00` 自行授权。

### Governance Bootstrap — 建卡、暂停与 fail-closed 状态机

bootstrap 的唯一职责是：

- 建立 `VSB-00..VSB-03` 卡片正文、README 和唯一 execution-state；
- 建立 Visual Style Baseline task-card validator 及其状态机负例；
- 扩展 Wave 1 task-card validator，使 `SUSPENDED_BY_USER` 成为显式、可恢复且
  fail-closed 的合法状态；
- 把 `W1-I03@4e63936` 原子置为 suspended，`ActiveTaskCard = NONE`；
- 写入集合级授权范围和固定候选不可变断言；
- 不创建参考图、Style Reference、CSS、组件、Visual Reference 或截图。

bootstrap 形成独立本地候选并使用新的 `deep_reviewer` 审查。只有
`GO / P0=0 / P1=0 / P2=0` 后，execution-state 才能用独立状态提交释放
`VSB-00`。bootstrap 失败时，不能开始任何视觉交付；若暂停状态已经写入，则恢复
`W1-I03` 必须使用独立、可审计的状态提交。

### VSB-00 — Governance、Reference 与正式 Style Reference

职责：

- 复核 Wave 1 lane 仍是 `SUSPENDED_BY_USER`；
- 复核 `W1-I03@4e63936` 未发生 mutation；
- 建立 authority/reference validator 及负例；
- 转码并登记参考图；
- 建立正式 Visual Style Reference；
- 更新既有视觉设计文档的权威桥接，不改历史证据。

Gate：`VSB-G0 GOVERNANCE_AND_REFERENCE`。

### VSB-01 — Semantic Token Projection

职责：

- 先写失败的 token contract tests；
- 建立五个 CSS 文件；
- 验证必需 Token、语义命名、无平行值、Typography、Focus 和 Surface 规则；
- 不修改组件或 Visual Reference 页面。

Gate：`VSB-G1 SEMANTIC_TOKENS`。

### VSB-02 — ModuleDefaultReading Visual Implementation

职责：

- 先写 DOM/style/anti-dashboard 失败测试；
- 重塑现有有限组件；
- 建立独立 Vite Visual Reference；
- 不修改 `App.tsx`、路由、后端、Schema 或 Canonical mapping。

Gate：`VSB-G2 MODULE_DEFAULT_READING_VISUAL`。

### VSB-03 — Render、Compare 与 Fixed Candidate Review

职责：

- Chrome 三档重捕获；
- computed style 和实际 DOM 探测；
- Reference Comparison；
- Visual Acceptance Report；
- 完整 Gate、固定候选审查和最终状态记录；
- 最终 GO 后用独立状态提交恢复 `W1-I03` 为唯一 `READY`。

Gate：`VSB-G3 FIXED_VISUAL_ACCEPTANCE`。

每张卡形成独立本地提交并由新的 `deep_reviewer` 审查固定 SHA；只有
`GO / P0=0 / P1=0 / P2=0` 才能释放后继。`VSB-03` 的完整固定候选使用
`ultra_gatekeeper` 作最终 GO/NO-GO。任何审查发现回到对应 Owner 卡修复并产生新
SHA；最终审查卡内不得夹带修复。

## 9. 验证策略

### 9.1 TDD

每张实现卡遵循：

```text
RED
→ observe expected failure
→ minimal GREEN
→ targeted verification
→ full applicable verification
→ exact write-set check
→ local commit
→ independent fixed-SHA review
```

测试必须对真实行为断言，不把 fixture 自报字段当证据。视觉回归发现的缺陷必须先有
可复现失败再修复。

### 9.2 工具链

```text
Node = 24.18.0
pnpm = 11.17.0
```

当前系统默认 `Node 23.11.0 / pnpm 9.15.9` 不符合基线。实施必须定位精确锁定版本；
不得放宽 `web/package.json` engines 或 packageManager。无法取得精确版本时为真实
Blocker，不得用近似版本声明 Gate PASS。

### 9.3 浏览器与 Viewport

必须使用本地 Chrome 对当前候选捕获：

```text
1440x1100
1280x960
1024x900
```

每档检查 Typography Hierarchy、Whitespace、Visual Density、Card Density、Control
Density、Focus Visibility、Reading Continuity、Semantic Color、Overflow 和
Responsive Safety。

### 9.4 Reference Comparison

生成参考图与新 `ModuleDefaultReadingState` 的并排证据。比较问题是：

```text
SameProductFamily
SameVisualCalmness
SameSurfaceCharacter
SameBorderCharacter
SameBluePurpleFamily
SameTypographyDensity
SameIconCharacter
SameRefinementLevel
SameSemanticColorRestraint
NewPageIsSubstantiallyMoreReadingFirst
```

不比较页面坐标，不追求像素复制，不增加旧图中的 Metrics、学习进度、覆盖率、统计、
永久右栏或治理 Dashboard。

### 9.5 既有回归

至少运行：

- Module reading Vitest；
- Web production build；
- `scripts/verify-module-default-reading`；
- 新 Visual Style Baseline verifier；
- 既有 `scripts/verify-high-fidelity-visual`，证明历史证据未被静默改写；
- Wave 1 task-card validator，证明暂停/恢复状态 fail-closed；
- `git diff --check` 和精确写集检查。

## 10. 视觉证据与报告

新增资产放在独立路径，不覆盖历史 HV evidence：

```text
docs/design/reference/Cognitive-Knowledge-Atlas-Dashboard.png
docs/design/visual-style-baseline/evidence/module-default-reading-1440x1100.png
docs/design/visual-style-baseline/evidence/module-default-reading-1280x960.png
docs/design/visual-style-baseline/evidence/module-default-reading-1024x900.png
docs/design/visual-style-baseline/evidence/reference-comparison.png
docs/engineering/cognitura-visual-style-baseline-acceptance.md
```

Evidence README 或 Manifest 必须记录状态、Viewport、候选 SHA、捕获命令、Chrome
版本、文件 SHA、computed style 结果和是否由当前候选新鲜重捕获。

## 11. 最终验收

只有以下全部为 `PASS` 才能声明 Visual Style Baseline 完成：

```text
SameProductVisualFamilyWithReference = PASS
ReadingFirst = PASS
InteractiveCognitiveDocument = PASS
ContinuousDocumentFlow = PASS
ZeroInteractionReading = PASS
CardAndContainerRestraint = PASS
VisualPrimitiveDensity = PASS
InteractionExposureRestraint = PASS
TypographyHierarchy = PASS
ColorSemanticConsistency = PASS
RelationSemanticExpression = PASS
NoDashboardRegression = PASS
NoCardWallRegression = PASS
NoAISaaSTemplateDrift = PASS
NoFormalDesignAuthorityViolation = PASS
```

任一项失败，最终状态必须为 `NO_GO`，不得声明高保真视觉设计完成。

即使十五项 Visual Style Baseline 验收全部通过，也只能声明：

```text
VisualStyleBaseline = PASS
ModuleDefaultReadingVisualImplementation = PASS_WITHIN_EXISTING_CANONICAL_PROJECTION
FullModuleDefaultReadingBusinessAcceptance = BLOCKED_BY_DOC_GAP_MDR_001
ImplementationValidation = NOT_CLAIMED_FOR_FULL_PRODUCT_PAGE
```

不得用 fixture-only Conditions/Results 把完整业务实现投影为 PASS。

## 12. 明确非目标

```text
AppIntegration = OUT_OF_SCOPE
ProductRoute = OUT_OF_SCOPE
HTTP = OUT_OF_SCOPE
Backend = OUT_OF_SCOPE
SchemaChange = OUT_OF_SCOPE
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
DashboardReconstruction = FORBIDDEN
HistoricalEvidenceOverwrite = FORBIDDEN
ReferenceScreenshotCloning = FORBIDDEN
FullProductPagePropagation = OUT_OF_SCOPE
```

Domain Panorama、Theme、Element、Verification 和 Revision 的样式传播必须等待本轮
固定候选最终 GO 后另行建立卡片，不能由本设计自动授权。
