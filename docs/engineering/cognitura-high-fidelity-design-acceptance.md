# Cognitura 高保真证据验收台账

```text
CanonicalProjectName = Cognitura
AcceptanceKind = HIGH_FIDELITY_EVIDENCE_ACCEPTANCE_LEDGER
ContractGate = HF-DG3
EvidenceArtifactCapture = NOT_RUN
HighFidelityVisualDesign = NOT_RUN
HighFidelityUsabilityValidation = NOT_RUN
ImplementationValidation = NOT_RUN
BusinessImplementation = NOT_AUTHORIZED
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

本台账仅定义未来验收行。所有 `Artifact` 都以 `PLANNED:` 标识，当前没有截图、
原型或执行记录；`Status=NOT_RUN` 不得改写为 PASS，直到所属 HV Gate 真实执行。

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

以下 30 行只确认候选、计划与验收台账之间仍可定位；它们不宣称视觉证据已执行。

```text
ReverseMigrationTrace = ISHFI-RM-01|Candidate=ISHFI-RM-01|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-02|Candidate=ISHFI-RM-02|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-03|Candidate=ISHFI-RM-03|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-04|Candidate=ISHFI-RM-04|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-05|Candidate=ISHFI-RM-05|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-06|Candidate=ISHFI-RM-06|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-07|Candidate=ISHFI-RM-07|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-08|Candidate=ISHFI-RM-08|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-09|Candidate=ISHFI-RM-09|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-10|Candidate=ISHFI-RM-10|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-11|Candidate=ISHFI-RM-11|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-12|Candidate=ISHFI-RM-12|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-13|Candidate=ISHFI-RM-13|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-14|Candidate=ISHFI-RM-14|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-15|Candidate=ISHFI-RM-15|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-16|Candidate=ISHFI-RM-16|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-17|Candidate=ISHFI-RM-17|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-18|Candidate=ISHFI-RM-18|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-19|Candidate=ISHFI-RM-19|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-20|Candidate=ISHFI-RM-20|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-21|Candidate=ISHFI-RM-21|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-22|Candidate=ISHFI-RM-22|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-23|Candidate=ISHFI-RM-23|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-24|Candidate=ISHFI-RM-24|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-25|Candidate=ISHFI-RM-25|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-26|Candidate=ISHFI-RM-26|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-27|Candidate=ISHFI-RM-27|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-28|Candidate=ISHFI-RM-28|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-29|Candidate=ISHFI-RM-29|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
ReverseMigrationTrace = ISHFI-RM-30|Candidate=ISHFI-RM-30|Plan=HFD03EvidenceContract|Acceptance=NOT_RUN|Status=TRACED
```

## 4. 当前 Gate 结论

```text
HF-DG3 HighFidelityEvidenceContract = PASS
GateMeaning = EVIDENCE_INPUT_CONTRACT_COMPLETE_ONLY
GateVisualEvidenceStatus = NOT_RUN
GateUsabilityEvidenceStatus = NOT_RUN
GateImplementationStatus = NOT_RUN
```

`HF-DG3` 不替代 HF-D04 固定候选审查，也不释放任何 HV 卡或 W1-I 卡。
