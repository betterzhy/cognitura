# Cognitura 高保真证据验收台账

```text
CanonicalProjectName = Cognitura
AcceptanceKind = HIGH_FIDELITY_EVIDENCE_ACCEPTANCE_LEDGER
ContractGate = HF-DG4 PASS
ReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf
ReviewStage1Model = gpt-5.6-sol/high
ReviewStage1Verdict = GO
ReviewStage1P0 = 0
ReviewStage1P1 = 0
ReviewStage1P2 = 0
ReviewStage2Model = gpt-5.6-sol/high
ReviewStage2Verdict = GO
ReviewStage2P0 = 0
ReviewStage2P1 = 0
ReviewStage2P2 = 0
UltraReviewUsed = NO
EvidenceArtifactCapture = NOT_RUN
HVExecutionArtifactCapture = PARTIAL_HV_D04
VisualFoundationArtifactCapture = PASS
VisualFoundationArtifact = docs/design/high-fidelity/evidence/visual-foundation-desktop.png
VisualFoundationViewport = DESKTOP_1440x1100
ModuleDefaultReadingArtifactCapture = PASS
ModuleDefaultReadingArtifact = docs/design/high-fidelity/evidence/module-default-reading-desktop.png
ModuleDefaultReadingViewport = DESKTOP_1440x1100
ModuleDefaultReadingValidationStage = HIGH_FIDELITY_VISUAL
RelationFocusArtifactCapture = PASS
RelationFocusArtifact = docs/design/high-fidelity/evidence/module-relation-focus-desktop.png
RelationFocusViewport = DESKTOP_1440x1100
SourceVerificationArtifactCapture = PASS
SourceVerificationArtifact = docs/design/high-fidelity/evidence/module-source-verification-desktop.png
SourceVerificationViewport = DESKTOP_1440x1100
FocusAndSourceValidationStage = HIGH_FIDELITY_VISUAL
RevisionImpactArtifactCapture = PASS
RevisionImpactArtifact = docs/design/high-fidelity/evidence/module-revision-impact-desktop.png
RevisionImpactViewport = DESKTOP_1440x1100
RecoveryArtifactCapture = PASS
RecoveryArtifact = docs/design/high-fidelity/evidence/module-recovery-desktop.png
RecoveryViewport = DESKTOP_1440x1100
ConflictedDraftArtifactCapture = PASS
ConflictedDraftArtifact = docs/design/high-fidelity/evidence/module-conflicted-draft-desktop.png
ConflictedDraftViewport = DESKTOP_1440x1100
RevisionAndRecoveryValidationStage = HIGH_FIDELITY_VISUAL
LandscapeThemeArtifactCapture = PASS
LandscapeThemeArtifact = docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png
LandscapeThemeViewport = DESKTOP_1440x1100
CrossDomainArtifactCapture = PASS
CrossDomainArtifact = docs/design/high-fidelity/evidence/cross-domain-reading-desktop.png
SmallScreenArtifactCapture = PASS
SmallScreenArtifact = docs/design/high-fidelity/evidence/module-default-reading-small-screen.png
SmallScreenViewport = SMALL_SCREEN_390x844
StaticExportArtifactCapture = PASS
StaticExportArtifact = docs/design/high-fidelity/evidence/static-export-example.png
StaticExportViewport = STATIC_EXPORT_1200x1600
StaticExportManifest = docs/design/high-fidelity/evidence/static-export-manifest.json
CrossLayerResponsiveAndExportValidationStage = HIGH_FIDELITY_VISUAL
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

`HV-D00` 已产生一张不绑定 RF 行的 foundation 截图与 docs-only 原型；`HV-D01`
又以求值后 DOM 和 Module 默认阅读截图，只推进其正式 Owner 集
`RF-AC-02,04,05,06,08,11,12` 的 `HIGH_FIDELITY_VISUAL` 结果；`HV-D02` 再以
Relation 聚焦、完整来源核验 DOM 与两张桌面截图，只推进 `RF-AC-03,07,09,16`；
`HV-D03` 再以修订影响、部分失败恢复、冲突草稿 DOM 与三张桌面截图，只推进
`RF-AC-13,14,17,18`；`HV-D04` 以四层/跨域、小屏和静态导出证据只推进
`RF-AC-01,10,15,19`。`RF-AC-20` 仅记录 supporting visual evidence，正式行仍为
`NOT_RUN`；全部正式异常输入行、整体视觉、可用性和实现结果仍为 `NOT_RUN`。

## 1. RF-AC 证据验收

```text
RFAcceptance = RF-AC-01|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|Scenario=FOUR_LAYER_ZERO_INTERACTION_TASK|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=FourLayerPrimaryCognitiveTaskCompletes|Artifact=PLANNED:docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png|Status=NOT_RUN|Gate=HV-D04
RFAcceptance = RF-AC-02|EvidenceClass=CognitiveModuleDefaultReading|Scenario=MODULE_DEFAULT_READING|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=CompleteCognitiveClosureWithoutInteraction|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
RFAcceptance = RF-AC-03|EvidenceClass=RelationFocus|Scenario=NO_PERSISTENT_RIGHT_PANEL|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+RELATION_PINNED|Expected=PrimaryRelationRemainsUnderstandable|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-relation-focus-desktop.png|Status=NOT_RUN|Gate=HV-D02
RFAcceptance = RF-AC-04|EvidenceClass=CognitiveModuleDefaultReading|Scenario=NO_CARD_GRID_PRIMARY_BODY|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=StructuredContinuousNarrativeIsPrimary|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
RFAcceptance = RF-AC-05|EvidenceClass=CognitiveModuleDefaultReading|Scenario=VISUAL_PRIMITIVE_RESTRAINT|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=NoMassCollectionOfIrregularComponents|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
RFAcceptance = RF-AC-06|EvidenceClass=CognitiveModuleDefaultReading|Scenario=CONTINUOUS_COGNITIVE_NARRATIVE|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=MechanismRelationConditionAndBoundaryConnected|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
RFAcceptance = RF-AC-07|EvidenceClass=SourceEvidenceVerification|Scenario=ON_DEMAND_GOVERNANCE_SURFACE|Viewport=DESKTOP_1440x1100|InputState=VERIFICATION_MODE+QUICK_SOURCE|Expected=NoPersistentGovernancePanel|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-source-verification-desktop.png|Status=NOT_RUN|Gate=HV-D02
RFAcceptance = RF-AC-08|EvidenceClass=CognitiveModuleDefaultReading|Scenario=DEFAULT_CONTROL_BUDGET|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=PageAndSectionBudgetsSatisfied|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
RFAcceptance = RF-AC-09|EvidenceClass=SourceEvidenceVerification|Scenario=CANONICAL_FACT_TRACE|Viewport=DESKTOP_1440x1100|InputState=VERIFICATION_MODE+FULL_VERIFICATION|Expected=EachFactComesOnlyFromCanonicalModel|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-source-verification-desktop.png|Status=NOT_RUN|Gate=HV-D02
RFAcceptance = RF-AC-10|EvidenceClass=StaticExport|Scenario=CROSS_PROJECTION_IDENTITY|Viewport=STATIC_EXPORT_1200x1600|InputState=PUBLISHED_CANONICAL_PROJECTION|Expected=ObjectAndRelationIdentityStableAcrossOutputs|Artifact=PLANNED:docs/design/high-fidelity/evidence/static-export-example.png|Status=NOT_RUN|Gate=HV-D04
RFAcceptance = RF-AC-11|EvidenceClass=CognitiveModuleDefaultReading|Scenario=KNOWLEDGE_ELEMENT_LOCATION_AND_EXPANSION|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+ELEMENT_PINNED|Expected=OrdinaryElementsAreNotAllCardsOrNodes|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
RFAcceptance = RF-AC-12|EvidenceClass=CognitiveModuleDefaultReading|Scenario=PERSPECTIVE_OPTIONALITY|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=CoreNarrativeDoesNotDependOnPerspectiveSwitch|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=NOT_RUN|Gate=HV-D01
RFAcceptance = RF-AC-13|EvidenceClass=RevisionAndImpact|Scenario=HIGH_RISK_IMPACT_BLOCKER|Viewport=DESKTOP_1440x1100|InputState=REVISION_MODE+COMMIT_BLOCKED|Expected=HighRiskImpactExpandedAndCommitBlocked|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-revision-impact-desktop.png|Status=NOT_RUN|Gate=HV-D03
RFAcceptance = RF-AC-14|EvidenceClass=Recovery|Scenario=POST_COMMIT_PROCESSING_AND_REVERT|Viewport=DESKTOP_1440x1100|InputState=CANONICAL_SAVED+PARTIAL_FAILURE|Expected=FourProcessingStatesPartialFailureAndRevertExplicit|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-recovery-desktop.png|Status=NOT_RUN|Gate=HV-D03
RFAcceptance = RF-AC-15|EvidenceClass=SmallScreenSafeReadable|Scenario=SMALL_SCREEN_DOCUMENT_FLOW|Viewport=SMALL_SCREEN_390x844|InputState=READING_MODE+IDLE|Expected=ContinuousDocumentRemainsSafeReadable|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-default-reading-small-screen.png|Status=NOT_RUN|Gate=HV-D04
RFAcceptance = RF-AC-16|EvidenceClass=RelationFocus|Scenario=CLICK_ESCAPE_BLANK_KEYBOARD_MATRIX|Viewport=DESKTOP_1440x1100|InputState=RELATION_PINNED+KEYBOARD_FOCUS|Expected=UniqueTransitionWithContextAndFocusRestored|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-relation-focus-desktop.png|Status=NOT_RUN|Gate=HV-D02
RFAcceptance = RF-AC-17|EvidenceClass=Recovery|Scenario=URL_HISTORY_REFRESH_RESTORE|Viewport=DESKTOP_1440x1100|InputState=REFRESH_RESTORING+RECOVERABLE_DRAFT|Expected=OnlyStableSemanticStateAndDraftRestore|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-recovery-desktop.png|Status=NOT_RUN|Gate=HV-D03
RFAcceptance = RF-AC-18|EvidenceClass=Recovery|Scenario=EXCEPTION_RECOVERY_MATRIX|Viewport=DESKTOP_1440x1100|InputState=FAILED+RECOVERABLE_DRAFT|Expected=SaveBoundaryRetryFallbackDedupAndFeedbackExplicit|Artifact=PLANNED:docs/design/high-fidelity/evidence/module-recovery-desktop.png|Status=NOT_RUN|Gate=HV-D03
RFAcceptance = RF-AC-19|EvidenceClass=StaticExport|Scenario=MACHINE_IDENTITY_READER_SILENCE|Viewport=STATIC_EXPORT_1200x1600|InputState=PUBLISHED_CANONICAL_PROJECTION|Expected=StableIdsMachineReadableAndReaderSilent|Artifact=PLANNED:docs/design/high-fidelity/evidence/static-export-example.png|Status=NOT_RUN|Gate=HV-D04
RFAcceptance = RF-AC-20|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|Scenario=LOW_TO_HIGH_FIDELITY_TRACE|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Expected=AcceptedConclusionsTraceToCurrentCandidate|Artifact=PLANNED:docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png|Status=NOT_RUN|Gate=HV-D05
```

## 2. 异常证据验收

```text
ExceptionAcceptance = EX-PREVIEW-TARGET-DELETED|EvidenceClass=RelationFocus|Scenario=PREVIEW_TARGET_DELETED|Viewport=DESKTOP_1440x1100|InputState=PREVIEW|Expected=PreviewClosesAndStableFocusReturnsWithFeedback|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-preview-target-deleted.png|Status=NOT_RUN|Gate=HV-D02
ExceptionAcceptance = EX-RELATION-SUPERSEDED|EvidenceClass=RelationFocus|Scenario=RELATION_SUPERSEDED|Viewport=DESKTOP_1440x1100|InputState=RELATION_PINNED|Expected=SupersededRelationExplainedAndOriginRestored|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-relation-superseded.png|Status=NOT_RUN|Gate=HV-D02
ExceptionAcceptance = EX-ELEMENT-PRIMARY-PARENT-CHANGED|EvidenceClass=CognitiveModuleDefaultReading|Scenario=ELEMENT_PARENT_CHANGED|Viewport=DESKTOP_1440x1100|InputState=ELEMENT_PINNED|Expected=CanonicalLocationRebasedWithoutSecondTree|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-element-parent-changed.png|Status=NOT_RUN|Gate=HV-D01
ExceptionAcceptance = EX-AUTO-UPGRADE-FAILED|EvidenceClass=RevisionAndImpact|Scenario=AUTO_UPGRADE_FAILED|Viewport=DESKTOP_1440x1100|InputState=AUTO_UPGRADING+DIRTY_DRAFT|Expected=DraftPreservedAndFullRevisionFallbackOffered|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-auto-upgrade-failed.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-IMPACT-ANALYSIS-FAILED|EvidenceClass=RevisionAndImpact|Scenario=IMPACT_ANALYSIS_FAILED|Viewport=DESKTOP_1440x1100|InputState=IMPACT_ANALYZING|Expected=CommitBlockedAndRetryScopeExplicit|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-impact-analysis-failed.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-CANONICAL-SAVED-RECOMPUTE-FAILED|EvidenceClass=Recovery|Scenario=CANONICAL_SAVED_RECOMPUTE_FAILED|Viewport=DESKTOP_1440x1100|InputState=CANONICAL_SAVED+PARTIAL_FAILURE|Expected=CanonicalSaveBoundaryAndRecomputeRetryExplicit|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-recompute-failed.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-CANONICAL-SAVED-GENERATION-FAILED|EvidenceClass=Recovery|Scenario=CANONICAL_SAVED_GENERATION_FAILED|Viewport=DESKTOP_1440x1100|InputState=CANONICAL_SAVED+PARTIAL_FAILURE|Expected=CanonicalSaveBoundaryAndGenerationRetryExplicit|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-generation-failed.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-GENERATED-CONFLICTS-LOCKED|EvidenceClass=Recovery|Scenario=GENERATED_CONFLICTS_LOCKED|Viewport=DESKTOP_1440x1100|InputState=CONFLICTED_DRAFT|Expected=LockedContentConflictBlocksReplacement|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-generated-locked-conflict.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-DRAFT-CONFLICTS-LATEST|EvidenceClass=Recovery|Scenario=DRAFT_CONFLICTS_LATEST|Viewport=DESKTOP_1440x1100|InputState=CONFLICTED_DRAFT|Expected=RebaseChoicePreservesDraftAndLatestCanonical|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-draft-conflict.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-SOURCE-INVALIDATED|EvidenceClass=SourceEvidenceVerification|Scenario=SOURCE_INVALIDATED|Viewport=DESKTOP_1440x1100|InputState=FULL_VERIFICATION+PENDING_VERIFICATION|Expected=InvalidSourceMarkedAndReverificationRequired|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-source-invalidated.png|Status=NOT_RUN|Gate=HV-D02
ExceptionAcceptance = EX-REFRESH-FOCUS-RESTORE-FAILED|EvidenceClass=Recovery|Scenario=REFRESH_FOCUS_RESTORE_FAILED|Viewport=DESKTOP_1440x1100|InputState=REFRESH_RESTORING|Expected=NearestCanonicalParentAndFailureFeedbackShown|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-refresh-focus-failed.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-SEMANTIC-ANCHOR-MOVED|EvidenceClass=Recovery|Scenario=SEMANTIC_ANCHOR_MOVED|Viewport=DESKTOP_1440x1100|InputState=HISTORY_RESTORING|Expected=AnchorRebasedExplicitlyWithoutSilentDefault|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-anchor-moved.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-SMALL-SCREEN-PANEL-OVERFLOW|EvidenceClass=SmallScreenSafeReadable|Scenario=SMALL_SCREEN_PANEL_OVERFLOW|Viewport=SMALL_SCREEN_390x844|InputState=FULL_VERIFICATION|Expected=WorkspaceBecomesSafeOverlayWithoutContentLoss|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-small-screen-overflow.png|Status=NOT_RUN|Gate=HV-D04
ExceptionAcceptance = EX-TOUCH-NO-HOVER|EvidenceClass=SmallScreenSafeReadable|Scenario=TOUCH_NO_HOVER|Viewport=SMALL_SCREEN_390x844|InputState=READING_MODE+IDLE|Expected=ExplicitTouchActionEqualsHoverInformation|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-touch-no-hover.png|Status=NOT_RUN|Gate=HV-D04
ExceptionAcceptance = EX-KEYBOARD-ENTERS-GRAPH|EvidenceClass=RelationFocus|Scenario=KEYBOARD_ENTERS_GRAPH|Viewport=DESKTOP_1440x1100|InputState=RELATION_PINNED+KEYBOARD_FOCUS|Expected=FocusOrderA11yLabelAndEscapeReturnDeterministic|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-keyboard-graph.png|Status=NOT_RUN|Gate=HV-D02
ExceptionAcceptance = EX-DUPLICATE-SUBMIT-CLICK|EvidenceClass=RevisionAndImpact|Scenario=DUPLICATE_SUBMIT_CLICK|Viewport=DESKTOP_1440x1100|InputState=SUBMITTING|Expected=DuplicateSubmissionDeduplicatedWithFeedback|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-duplicate-submit.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-NETWORK-TIMEOUT-SAVE-UNKNOWN|EvidenceClass=Recovery|Scenario=NETWORK_TIMEOUT_SAVE_UNKNOWN|Viewport=DESKTOP_1440x1100|InputState=SUBMITTING|Expected=SameIdempotencyKeyQueriesOriginalResult|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-save-unknown.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-UI-FAILED-CANONICAL-SAVED|EvidenceClass=Recovery|Scenario=UI_FAILED_CANONICAL_SAVED|Viewport=DESKTOP_1440x1100|InputState=CANONICAL_SAVED+FAILED|Expected=CanonicalSavedTruthShownAndNoFalseRollback|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-ui-failed-canonical-saved.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-REVERT-AFFECTS-LATER-CHANGES|EvidenceClass=Recovery|Scenario=REVERT_AFFECTS_LATER_CHANGES|Viewport=DESKTOP_1440x1100|InputState=REVISION_MODE+IMPACT_ANALYZING|Expected=RevertCreatesNewChangeSetAfterImpactReview|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-revert-impact.png|Status=NOT_RUN|Gate=HV-D03
ExceptionAcceptance = EX-WORKSPACE-SWITCH-WITH-DRAFT|EvidenceClass=Recovery|Scenario=WORKSPACE_SWITCH_WITH_DRAFT|Viewport=DESKTOP_1440x1100|InputState=DIRTY_DRAFT|Expected=SaveDiscardCancelGuardPreservesFocusAndDraft|Artifact=PLANNED:docs/design/high-fidelity/evidence/exception-workspace-switch-draft.png|Status=NOT_RUN|Gate=HV-D03
```

## 3. Reverse Migration 追溯

以下 30 行把候选条目绑定到具体证据类、八类证据路径和真实 RF/Exception
验收 ID；它们只证明追溯可定位，不宣称视觉证据已执行。

```text
ReverseMigrationTrace = ISHFI-RM-01|Candidate=ISHFI-RM-01|EvidenceClass=RelationFocus|EvidencePath=02|AcceptanceIds=RF-AC-03,EX-PREVIEW-TARGET-DELETED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-02|Candidate=ISHFI-RM-02|EvidenceClass=SmallScreenSafeReadable|EvidencePath=07|AcceptanceIds=RF-AC-15,EX-TOUCH-NO-HOVER|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-03|Candidate=ISHFI-RM-03|EvidenceClass=RelationFocus|EvidencePath=02|AcceptanceIds=RF-AC-16,EX-RELATION-SUPERSEDED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-04|Candidate=ISHFI-RM-04|EvidenceClass=RevisionAndImpact|EvidencePath=04|AcceptanceIds=RF-AC-13,EX-AUTO-UPGRADE-FAILED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-05|Candidate=ISHFI-RM-05|EvidenceClass=RevisionAndImpact|EvidencePath=04|AcceptanceIds=RF-AC-13,EX-IMPACT-ANALYSIS-FAILED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-06|Candidate=ISHFI-RM-06|EvidenceClass=RevisionAndImpact|EvidencePath=04|AcceptanceIds=RF-AC-13,EX-IMPACT-ANALYSIS-FAILED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-07|Candidate=ISHFI-RM-07|EvidenceClass=Recovery|EvidencePath=05|AcceptanceIds=RF-AC-14,EX-CANONICAL-SAVED-RECOMPUTE-FAILED,EX-CANONICAL-SAVED-GENERATION-FAILED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-08|Candidate=ISHFI-RM-08|EvidenceClass=Recovery|EvidencePath=05|AcceptanceIds=RF-AC-18,EX-CANONICAL-SAVED-RECOMPUTE-FAILED,EX-CANONICAL-SAVED-GENERATION-FAILED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-09|Candidate=ISHFI-RM-09|EvidenceClass=Recovery|EvidencePath=05|AcceptanceIds=RF-AC-17,EX-REFRESH-FOCUS-RESTORE-FAILED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-10|Candidate=ISHFI-RM-10|EvidenceClass=Recovery|EvidencePath=05|AcceptanceIds=RF-AC-18,EX-DRAFT-CONFLICTS-LATEST,EX-REVERT-AFFECTS-LATER-CHANGES|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-11|Candidate=ISHFI-RM-11|EvidenceClass=SmallScreenSafeReadable|EvidencePath=07|AcceptanceIds=RF-AC-15,EX-SMALL-SCREEN-PANEL-OVERFLOW,EX-TOUCH-NO-HOVER|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-12|Candidate=ISHFI-RM-12|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-02|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-13|Candidate=ISHFI-RM-13|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-02|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-14|Candidate=ISHFI-RM-14|EvidenceClass=Recovery|EvidencePath=05|AcceptanceIds=RF-AC-18|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-15|Candidate=ISHFI-RM-15|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|EvidencePath=06|AcceptanceIds=RF-AC-01,RF-AC-20|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-16|Candidate=ISHFI-RM-16|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-02,RF-AC-06|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-17|Candidate=ISHFI-RM-17|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-02|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-18|Candidate=ISHFI-RM-18|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-06|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-19|Candidate=ISHFI-RM-19|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-04,RF-AC-11|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-20|Candidate=ISHFI-RM-20|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-05,RF-AC-08|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-21|Candidate=ISHFI-RM-21|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-08|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-22|Candidate=ISHFI-RM-22|EvidenceClass=SourceEvidenceVerification|EvidencePath=03|AcceptanceIds=RF-AC-07,RF-AC-09|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-23|Candidate=ISHFI-RM-23|EvidenceClass=StaticExport|EvidencePath=08|AcceptanceIds=RF-AC-10,RF-AC-19|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-24|Candidate=ISHFI-RM-24|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|EvidencePath=06|AcceptanceIds=RF-AC-20|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-25|Candidate=ISHFI-RM-25|EvidenceClass=Recovery|EvidencePath=05|AcceptanceIds=RF-AC-17,RF-AC-18|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-26|Candidate=ISHFI-RM-26|EvidenceClass=RelationFocus|EvidencePath=02|AcceptanceIds=RF-AC-16,EX-KEYBOARD-ENTERS-GRAPH|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-27|Candidate=ISHFI-RM-27|EvidenceClass=Recovery|EvidencePath=05|AcceptanceIds=RF-AC-18,EX-NETWORK-TIMEOUT-SAVE-UNKNOWN,EX-UI-FAILED-CANONICAL-SAVED|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-28|Candidate=ISHFI-RM-28|EvidenceClass=CognitiveModuleDefaultReading|EvidencePath=01|AcceptanceIds=RF-AC-08|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-29|Candidate=ISHFI-RM-29|EvidenceClass=StaticExport|EvidencePath=08|AcceptanceIds=RF-AC-19|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-30|Candidate=ISHFI-RM-30|EvidenceClass=KnowledgeLandscapeAndKnowledgeTheme|EvidencePath=06|AcceptanceIds=RF-AC-20|Status=TRACED
```

## 4. HV-D00 视觉基础记录

```text
VisualFoundationAcceptance = HV-D00|Scenario=VISUAL_FOUNDATION|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Artifact=docs/design/high-fidelity/evidence/visual-foundation-desktop.png|Status=PASS
VisualFoundationScope = TOKENS,RESPONSIVE_THRESHOLDS,A11Y_FOCUS,READING_FIRST_ZERO_PERSISTENT_GOVERNANCE_SIDEBAR,ON_DEMAND_SOURCE_EVIDENCE,URL_ONLY_FIXTURE
VisualFoundationDoesNotClose = HV-D01,HV-D02,HV-D03,HV-D04,HV-D05
```

## 5. HV-D01 Module 默认阅读视觉记录

```text
ModuleDefaultReadingAcceptance = HV-D01|Scenario=MODULE_DEFAULT_READING|Viewport=DESKTOP_1440x1100|InputState=READING_MODE+IDLE|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|DOMState=module-default|Status=PASS|ValidationStage=HIGH_FIDELITY_VISUAL
ModuleDefaultReadingClosure = CoreQuestion,CoreConclusion,ContinuousNarrative,PrimaryCognitiveSpine,OnePrimaryProjection,Conditions,Results,BoundariesAndExceptions,TwoRelations,KnowledgeElementEntry,SourceEvidenceEntry
ModuleDefaultReadingRFOwnerPass = RF-AC-02,04,05,06,08,11,12
ModuleDefaultReadingFutureRFStatus = NOT_RUN
ModuleDefaultReadingPersistentGovernanceSidePanels = 0
ModuleDefaultReadingUsabilityStatus = NOT_RUN
ModuleDefaultReadingImplementationStatus = NOT_RUN

HVVisualAcceptanceObservation = RF-AC-02|Owner=HV-D01|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-04|Owner=HV-D01|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-05|Owner=HV-D01|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-06|Owner=HV-D01|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-08|Owner=HV-D01|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-11|Owner=HV-D01|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-12|Owner=HV-D01|Artifact=docs/design/high-fidelity/evidence/module-default-reading-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
```

## 6. HV-D02 Relation 聚焦与来源核验视觉记录

```text
FocusAndSourceAcceptance = HV-D02|Scenarios=RELATION_PINNED_FOCUS,FULL_VERIFICATION_WORKSPACE|Viewport=DESKTOP_1440x1100|Artifacts=docs/design/high-fidelity/evidence/module-relation-focus-desktop.png,docs/design/high-fidelity/evidence/module-source-verification-desktop.png|Status=PASS|ValidationStage=HIGH_FIDELITY_VISUAL
RelationFocusClosure = OnePrimaryRelation,OriginAnchor,CompleteStatement,TwoSecondaryEndpoints,EvidenceSupportScope,ExplicitClose,EscapeFocusReturn
SourceVerificationClosure = CanonicalTarget,OriginalReadingAnchor,SupportMatrix,DirectSupport,Recomposition,LimitedScope,Conflict,SourceGap,EscapeFocusReturn
FocusAndSourceRFOwnerPass = RF-AC-03,07,09,16
FocusAndSourceFutureRFStatus = NOT_RUN
FocusAndSourceIndependentFactCount = 0
FocusAndSourceUsabilityStatus = NOT_RUN
FocusAndSourceImplementationStatus = NOT_RUN

HVVisualAcceptanceObservation = RF-AC-03|Owner=HV-D02|Artifact=docs/design/high-fidelity/evidence/module-relation-focus-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-07|Owner=HV-D02|Artifact=docs/design/high-fidelity/evidence/module-source-verification-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-09|Owner=HV-D02|Artifact=docs/design/high-fidelity/evidence/module-source-verification-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-16|Owner=HV-D02|Artifact=docs/design/high-fidelity/evidence/module-relation-focus-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-13|Owner=HV-D03|Artifact=docs/design/high-fidelity/evidence/module-revision-impact-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-14|Owner=HV-D03|Artifact=docs/design/high-fidelity/evidence/module-recovery-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-17|Owner=HV-D03|Artifact=docs/design/high-fidelity/evidence/module-recovery-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-18|Owner=HV-D03|Artifact=docs/design/high-fidelity/evidence/module-recovery-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-01|Owner=HV-D04|Artifact=docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-10|Owner=HV-D04|Artifact=docs/design/high-fidelity/evidence/static-export-example.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-15|Owner=HV-D04|Artifact=docs/design/high-fidelity/evidence/module-default-reading-small-screen.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVVisualAcceptanceObservation = RF-AC-19|Owner=HV-D04|Artifact=docs/design/high-fidelity/evidence/static-export-example.png|Status=PASS_HIGH_FIDELITY_VISUAL_ONLY|Usability=NOT_RUN|Implementation=NOT_RUN
HVSupportingVisualEvidence = RF-AC-20|Owner=HV-D04|Artifact=docs/design/high-fidelity/evidence/knowledge-landscape-theme-desktop.png|SupplementalArtifact=docs/design/high-fidelity/evidence/cross-domain-reading-desktop.png|Status=CAPTURED_NOT_CLOSED|FormalRFAcceptance=NOT_RUN|Gate=HV-D05
```

## 7. 当前 Gate 结论

```text
HF-DG3 HighFidelityEvidenceContract = PASS
HF-DG4 FixedDesignReview = PASS
GateReviewedPreparationSHA = 463fd4829e7c4bb8da071253e8ae9b15cee2a0cf
GateMeaning = EVIDENCE_INPUT_CONTRACT_COMPLETE_ONLY
GateVisualEvidenceStatus = NOT_RUN
GateUsabilityEvidenceStatus = NOT_RUN
GateImplementationStatus = NOT_RUN
```

`HF-DG4` 只关闭合同设计固定候选审查；`HV-D00` 只关闭视觉基础，`HV-D01` 关闭
Module 默认阅读的七项 RF Owner 视觉结果，`HV-D02` 关闭 Relation/Source 的四项
RF Owner 视觉结果，`HV-D03` 关闭 Revision/Recovery 的四项 RF Owner 视觉结果并
释放 `HV-D04`；`HV-D04` 再关闭四项视觉 Owner 并释放 `HV-D05`。整体视觉与可用性
仍需固定候选双阶段审查，W1-I 业务实现仍未授权。
