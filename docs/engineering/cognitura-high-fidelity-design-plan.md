# Cognitura 高保真证据执行计划

```text
CanonicalProjectName = Cognitura
PlanKind = HIGH_FIDELITY_EVIDENCE_EXECUTION_PLAN
ContractGate = HF-DG4 PASS
EvidenceInputContract = PASS
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
HighFidelityVisualFoundation = PASS
HighFidelityModuleDefaultReading = PASS
HighFidelityFocusAndSource = PASS
HighFidelityRevisionAndRecovery = PASS
HighFidelityCrossLayerResponsiveAndExport = PASS
VisualTaskCardArtifactsActual = CREATED
HV-D00ReleaseCondition = HF_D04_FIXED_CANDIDATE_DOUBLE_REVIEW_PASS
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

本文件固定后续证据路径、输入状态和 Gate。`HV-D00` 已建立 docs-only 非生产原型
基础和一张 1440×1100 foundation 截图；`HV-D01` 已建立 Module 默认阅读证据；
`HV-D02` 已建立 Relation 聚焦与完整来源核验的两张桌面证据；`HV-D03` 已建立修订
影响、部分失败恢复和冲突草稿三张桌面证据；`HV-D04` 已建立四层/跨域、小屏与静态
导出证据，只关闭各卡所属的正式 RF Owner 视觉观察。整体视觉设计与可用性结果仍为
`NOT_RUN`。

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

以下 `HVDesignTask` 六行是 `HF-DG4` 关闭时的历史投影快照，继续供合同 Gate
复验；`VisualTaskCardArtifacts = NOT_CREATED` 也只表示该历史时点。Task 6 此后已
创建精确六卡集合、视觉基础、确定性原型和 foundation 截图并关闭 `HV-D00`。
当前实际状态由 `HVExecutionTask` 六行承担，六卡均已完成。

```text
VisualTaskCardArtifacts = NOT_CREATED
HVDesignTask = HV-D00|VisualFoundation|READY|RELEASED
HVDesignTask = HV-D01|ModuleDefaultReading|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D02|FocusAndSource|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D03|RevisionAndRecovery|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D04|CrossLayerResponsiveAndExport|BLOCKED|NOT_RELEASED
HVDesignTask = HV-D05|FixedVisualUsabilityReview|BLOCKED|NOT_RELEASED

HVExecutionTask = HV-D00|VisualFoundation|DONE|PASS
HVExecutionTask = HV-D01|ModuleDefaultReading|DONE|PASS
HVExecutionTask = HV-D02|FocusAndSource|DONE|PASS
HVExecutionTask = HV-D03|RevisionAndRecovery|DONE|PASS
HVExecutionTask = HV-D04|CrossLayerResponsiveAndExport|DONE|PASS
HVExecutionTask = HV-D05|FixedVisualUsabilityReview|DONE|PASS
```

## 4. 视觉基础证据

```text
VisualFoundationArtifact = docs/design/high-fidelity/evidence/visual-foundation-desktop.png
VisualFoundationViewport = DESKTOP_1440x1100
VisualFoundationPrototypeState = visual-foundation
VisualFoundationStatus = PASS
VisualFoundationMeaning = TOKEN_AND_PROTOTYPE_GOVERNANCE_BASELINE_ONLY
```

## 5. Module 默认阅读证据

```text
ModuleDefaultReadingArtifact = docs/design/high-fidelity/evidence/module-default-reading-desktop.png
ModuleDefaultReadingViewport = DESKTOP_1440x1100
ModuleDefaultReadingPrototypeState = module-default
ModuleDefaultReadingStatus = PASS
ModuleDefaultReadingValidationStage = HIGH_FIDELITY_VISUAL
ModuleDefaultReadingRFOwnerPass = RF-AC-02,04,05,06,08,11,12
ModuleDefaultReadingDoesNotClose = RF-AC-01,03,07,09,10,13,14,15,16,17,18,19,20
HVExecutionEvidence = HV-D01|EvidencePath=01|EvidenceClass=CognitiveModuleDefaultReading|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D01 PASS
```

## 6. Relation 聚焦与来源核验证据

```text
RelationFocusArtifact = docs/design/high-fidelity/evidence/module-relation-focus-desktop.png
RelationFocusViewport = DESKTOP_1440x1100
RelationFocusPrototypeState = relation-focus
RelationFocusStatus = PASS
SourceVerificationArtifact = docs/design/high-fidelity/evidence/module-source-verification-desktop.png
SourceVerificationViewport = DESKTOP_1440x1100
SourceVerificationPrototypeState = source-verification
SourceVerificationStatus = PASS
FocusAndSourceValidationStage = HIGH_FIDELITY_VISUAL
FocusAndSourceRFOwnerPass = RF-AC-03,07,09,16
FocusAndSourceDoesNotClose = RF-AC-01,02,04,05,06,08,10,11,12,13,14,15,17,18,19,20
HVExecutionEvidence = HV-D02|EvidencePath=02|EvidenceClass=RelationFocus|Artifact=docs/design/high-fidelity/evidence/module-relation-focus-desktop.png|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D02 PASS
HVExecutionEvidence = HV-D02|EvidencePath=03|EvidenceClass=SourceEvidenceVerification|Artifact=docs/design/high-fidelity/evidence/module-source-verification-desktop.png|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D02 PASS
```

## 7. 修订、影响与恢复证据

```text
RevisionImpactArtifact = docs/design/high-fidelity/evidence/module-revision-impact-desktop.png
RevisionImpactViewport = DESKTOP_1440x1100
RevisionImpactPrototypeState = revision-impact
RevisionImpactStatus = PASS
RecoveryArtifact = docs/design/high-fidelity/evidence/module-recovery-desktop.png
RecoveryViewport = DESKTOP_1440x1100
RecoveryPrototypeState = partial-failure
RecoveryStatus = PASS
ConflictedDraftArtifact = docs/design/high-fidelity/evidence/module-conflicted-draft-desktop.png
ConflictedDraftViewport = DESKTOP_1440x1100
ConflictedDraftPrototypeState = conflicted-draft
ConflictedDraftStatus = PASS
RevisionAndRecoveryValidationStage = HIGH_FIDELITY_VISUAL
RevisionAndRecoveryRFOwnerPass = RF-AC-13,14,17,18
RevisionAndRecoveryDoesNotClose = RF-AC-01,02,03,04,05,06,07,08,09,10,11,12,15,16,19,20
HVExecutionEvidence = HV-D03|EvidencePath=04|EvidenceClass=RevisionAndImpact|Artifact=docs/design/high-fidelity/evidence/module-revision-impact-desktop.png|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D03 PASS
HVExecutionEvidence = HV-D03|EvidencePath=05|EvidenceClass=Recovery|Artifact=docs/design/high-fidelity/evidence/module-recovery-desktop.png|SupplementalArtifact=docs/design/high-fidelity/evidence/module-conflicted-draft-desktop.png|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D03 PASS
HVUsabilityExecutionEvidence = HV-D05-STAGE2-REPAIR|Owners=RF-AC-07,13,14,16,17,18|Artifacts=docs/design/high-fidelity/evidence/module-relation-focus-desktop.png,docs/design/high-fidelity/evidence/module-source-verification-desktop.png,docs/design/high-fidelity/evidence/module-revision-impact-desktop.png,docs/design/high-fidelity/evidence/module-recovery-desktop.png,docs/design/high-fidelity/evidence/module-conflicted-draft-desktop.png|TransitionProbe=EVALUATED_DOM_AND_HISTORY_LIFECYCLE|Status=PASS_HIGH_FIDELITY_USABILITY_ONLY|FormalRFAcceptance=NOT_RUN|Implementation=NOT_RUN
HVUsabilityExceptionEvidence = HV-D05-STAGE2-REPAIR|ExceptionCount=20|TransitionProbe=EVALUATED_DOM_RECOVERY_ACTION_AND_FOCUS|Status=PASS_HIGH_FIDELITY_USABILITY_ONLY|FormalExceptionAcceptance=NOT_RUN|Implementation=NOT_RUN
```

## 8. 跨层、小屏与静态导出证据

```text
LandscapeThemeArtifact = docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png
LandscapeThemeViewport = DESKTOP_1440x1100
LandscapeThemePrototypeState = domain-default
CrossDomainArtifact = docs/design/high-fidelity/evidence/cross-domain-reading-desktop.png
CrossDomainViewport = DESKTOP_1440x1100
CrossDomainPrototypeState = theme-default
SmallScreenArtifact = docs/design/high-fidelity/evidence/module-default-reading-small-screen.png
SmallScreenViewport = SMALL_SCREEN_390x844
SmallScreenPrototypeState = module-small-screen
StaticExportArtifact = docs/design/high-fidelity/evidence/static-export-example.png
StaticExportViewport = STATIC_EXPORT_1200x1600
StaticExportPrototypeState = static-export
StaticExportManifest = docs/design/high-fidelity/evidence/static-export-manifest.json
CrossLayerResponsiveAndExportStatus = PASS
CrossLayerResponsiveAndExportValidationStage = HIGH_FIDELITY_VISUAL
CrossLayerResponsiveAndExportRFOwnerPass = RF-AC-01,10,15,19
RF-AC-20SupportingEvidence = CAPTURED_NOT_CLOSED
CrossLayerResponsiveAndExportDoesNotClose = RF-AC-02,03,04,05,06,07,08,09,11,12,13,14,16,17,18,20
HVExecutionEvidence = HV-D04|EvidencePath=06|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|Artifact=docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png|SupplementalArtifact=docs/design/high-fidelity/evidence/cross-domain-reading-desktop.png|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D04 PASS
HVExecutionEvidence = HV-D04|EvidencePath=07|EvidenceClass=SmallScreenSafeReadable|Artifact=docs/design/high-fidelity/evidence/module-default-reading-small-screen.png|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D04 PASS
HVExecutionEvidence = HV-D04|EvidencePath=08|EvidenceClass=StaticExport|Artifact=docs/design/high-fidelity/evidence/static-export-example.png|CompanionManifest=docs/design/high-fidelity/evidence/static-export-manifest.json|Status=CAPTURED|ValidationStage=HIGH_FIDELITY_VISUAL|Gate=HV-D04 PASS
```

## 9. 阶段隔离

```text
CONTRACT = HF-DG3_EVIDENCE_INPUT_CONTRACT_PASS
HIGH_FIDELITY_VISUAL = NOT_RUN
HIGH_FIDELITY_USABILITY = NOT_RUN
IMPLEMENTATION = NOT_RUN
W1-I00Creation = FORBIDDEN
W1-I00Release = FORBIDDEN
```

合同 PASS 不得推导视觉、可用性、实现、正式数据库写入或远程推送 PASS。

## 10. HV-D05 固定候选审查

```text
HV-D05ReviewedCandidateSHA = 62da1bc08a932bbfc76769a2add984dcec4160b7
HV-D05ReviewStage1 = GO|Model=gpt-5.6-sol/high|P0=0|P1=0|P2=0
HV-D05ReviewStage2 = GO|Model=gpt-5.6-sol/high|P0=0|P1=0|P2=0
HV-D05FixedVisualUsabilityReview = PASS
HVExecutionVisualDesign = PASS
HVExecutionVisualValidation = PASS
HVExecutionUsabilityValidation = PASS
HVExecutionStateAcceptance = PASS
HVExecutionImplementationValidation = NOT_RUN
```
