# Cognitura 高保真证据执行计划

```text
CanonicalProjectName = Cognitura
PlanKind = HIGH_FIDELITY_EVIDENCE_EXECUTION_PLAN
ContractGate = HF-DG4 PASS
EvidenceInputContract = PASS
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
VisualTaskCardArtifacts = NOT_CREATED
HV-D00ReleaseCondition = HF_D04_FIXED_CANDIDATE_DOUBLE_REVIEW_PASS
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

本文件只固定后续证据路径、输入状态和 Gate，不包含视觉页面、原型、截图或可用性
结果。`HF-DG4 = PASS` 只关闭合同设计固定候选审查；所有真实证据仍为 `NOT_RUN`。

## 1. 八类有序证据路径

`Artifact=PLANNED:` 只登记未来产物路径，不表示文件存在、已捕获或已通过。

```text
EvidencePath = 01|CognitiveModuleDefaultReading|Scenario=DEFAULT_READING_CLOSURE|Viewport=DESKTOP_WEB|InputState=READING_MODE+IDLE|Coverage=CoreQuestion,CoreConclusion,PrimaryCognitiveSpine,KnowledgeElementLocationAndExpansion,Relation,SourceEntry|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
EvidencePath = 02|RelationFocus|Scenario=SINGLE_PRIMARY_RELATION_FOCUS|Viewport=DESKTOP_WEB|InputState=READING_MODE+RELATION_PINNED|Coverage=OriginAnchor,Endpoints,SourceScope,KeyboardFocusReturn,Feedback|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-relation-focus-desktop.png|Status=NOT_RUN|Gate=HV-D02
EvidencePath = 03|SourceEvidenceVerification|Scenario=QUICK_AND_FULL_SOURCE_VERIFICATION|Viewport=DESKTOP_WEB|InputState=VERIFICATION_MODE+FULL_VERIFICATION|Coverage=SourceSupportScope,Conflict,Gap,PermissionDenied,Unavailable,A11y|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-source-verification-desktop.png|Status=NOT_RUN|Gate=HV-D02
EvidencePath = 04|RevisionAndImpact|Scenario=REVISION_THREE_LANE_IMPACT|Viewport=DESKTOP_WEB|InputState=REVISION_MODE+IMPACT_ANALYZING|Coverage=BeforeAfter,SemanticImpact,StructuralImpact,ExpressionImpact,CommitBlocker,Feedback|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-revision-impact-desktop.png|Status=NOT_RUN|Gate=HV-D03
EvidencePath = 05|Recovery|Scenario=REFRESH_HISTORY_CONFLICT_AND_PARTIAL_FAILURE|Viewport=DESKTOP_WEB|InputState=RECOVERABLE_DRAFT+PARTIAL_FAILURE|Coverage=Loading,Empty,Error,Retry,SubmitUnknown,Stale,Revert,FocusRestore|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-recovery-desktop.png|Status=NOT_RUN|Gate=HV-D03
EvidencePath = 06|KnowledgeLandscapeAndKnowledgeTheme|Scenario=CROSS_LAYER_DEFAULT_READING|Viewport=DESKTOP_WEB|InputState=READING_MODE+IDLE|Coverage=KnowledgeLandscape,KnowledgeTheme,CognitiveModule,KnowledgeElement,UnderstandingRoute,Closure|Artifact=PLANNED:docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png|Status=NOT_RUN|Gate=HV-D04
EvidencePath = 07|SmallScreenSafeReadable|Scenario=RESPONSIVE_SAFE_READING|Viewport=SMALL_SCREEN_390x844|InputState=READING_MODE+IDLE|Coverage=DocumentFlow,NoPersistentSidePanel,KnowledgeElementExpansion,TouchEquivalent,KeyboardFocus,A11y|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-small-screen.png|Status=NOT_RUN|Gate=HV-D04
EvidencePath = 08|StaticExport|Scenario=STABLE_IDENTITY_EXPORT|Viewport=STATIC_EXPORT_1200x1600|InputState=PUBLISHED_CANONICAL_PROJECTION|Coverage=StableObjectIdentity,StableRelationIdentity,SourceTrace,DefaultReaderSilence|Artifact=PLANNED:docs/design/high-fidelity/evidence/static-export-example.png|Status=NOT_RUN|Gate=HV-D04
```

```text
CoverageRequirement = KnowledgeElementLocationAndExpansion|REQUIRED|Status=NOT_RUN
CoverageRequirement = PageLifecycle|LOADING,EMPTY,ERROR,PERMISSION_DENIED,UNAVAILABLE|Status=NOT_RUN
CoverageRequirement = KeyboardFocusAccessibilityFeedback|KEYBOARD_FOCUS,A11Y,FEEDBACK|Status=NOT_RUN
CoverageRequirement = Viewport|DESKTOP_WEB,SMALL_SCREEN_SAFE_READABLE|Status=NOT_RUN
```

## 2. 跨领域场景

两个案例都只投影到正式四层结构，机制与规则/政策是 `CognitiveModule` 的内容形态，
不是新的产品对象、层级或全局知识图。

```text
CrossDomainScenario = MECHANISM_DOMAIN|EvidenceClass=CognitiveModuleDefaultReading|CanonicalProjection=KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement|Scenario=MVCC_CONSISTENT_READ_MECHANISM|Status=NOT_RUN|Gate=HV-D04
CrossDomainScenario = RULE_POLICY_DOMAIN|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|CanonicalProjection=KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement|Scenario=PROCUREMENT_ACCEPTANCE_BEFORE_PAYMENT_POLICY|Status=NOT_RUN|Gate=HV-D04
```

## 3. 后续视觉设计任务序列

本卡只登记序列，不创建 `docs/task-cards/high-fidelity-visual/`、原型或视觉稿。
HF-D04 固定候选双阶段审查已通过，因此仅投影 `HV-D00 = READY / RELEASED`。
实际 HV 卡集仍为 `NOT_CREATED`，由 Task 6 创建；其余五项继续阻断。

```text
HVDesignTask = HV-D00|VisualFoundation|READY|RELEASED
HVDesignTask = HV-D01|ModuleDefaultReading|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D02|FocusAndSource|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D03|RevisionAndRecovery|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D04|CrossLayerResponsiveAndExport|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D05|FixedVisualUsabilityReview|BLOCKED|NOT_RELEASED
```

## 4. 阶段隔离

```text
CONTRACT = HF-DG3_EVIDENCE_INPUT_CONTRACT_PASS
HIGH_FIDELITY_VISUAL = NOT_RUN
HIGH_FIDELITY_USABILITY = NOT_RUN
IMPLEMENTATION = NOT_RUN
W1-I00Creation = FORBIDDEN
W1-I00Release = FORBIDDEN
```

合同 PASS 不得推导视觉、可用性、实现、正式数据库写入或远程推送 PASS。
