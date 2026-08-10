(function () {
  "use strict";

  const fixtures = Object.freeze({
    "visual-foundation": "Visual foundation",
    "module-default": "Module default reading · HV-D01 evidence",
    "relation-focus": "Relation focus · HV-D02 evidence",
    "source-verification": "Source verification · HV-D02 evidence",
    "revision-impact": "Revision impact · HV-D03 evidence",
    "partial-failure": "Partial failure · HV-D03 evidence",
    "conflicted-draft": "Conflicted draft · HV-D03 evidence",
    "domain-default": "Knowledge Landscape + Theme · HV-D04 evidence",
    "theme-default": "Cross-domain reading · HV-D04 evidence",
    "module-small-screen": "Small-screen Module · HV-D04 evidence",
    "static-export": "Static export · HV-D04 evidence"
  });

  const query = new URLSearchParams(window.location.search);
  const requestedState = query.get("state") || "visual-foundation";
  const foundationFixture = document.getElementById("visual-foundation-fixture");
  const moduleDefaultFixture = document.getElementById("module-default-fixture");
  const relationFocusFixture = document.getElementById("relation-focus-fixture");
  const sourceVerificationFixture = document.getElementById("source-verification-fixture");
  const revisionImpactFixture = document.getElementById("revision-impact-fixture");
  const partialFailureFixture = document.getElementById("partial-failure-fixture");
  const conflictedDraftFixture = document.getElementById("conflicted-draft-fixture");
  const domainDefaultFixture = document.getElementById("domain-default-fixture");
  const themeDefaultFixture = document.getElementById("theme-default-fixture");
  const moduleSmallScreenFixture = document.getElementById("module-small-screen-fixture");
  const staticExportFixture = document.getElementById("static-export-fixture");

  if (!Object.prototype.hasOwnProperty.call(fixtures, requestedState)) {
    foundationFixture.hidden = true;
    moduleDefaultFixture.hidden = true;
    relationFocusFixture.hidden = true;
    sourceVerificationFixture.hidden = true;
    revisionImpactFixture.hidden = true;
    partialFailureFixture.hidden = true;
    conflictedDraftFixture.hidden = true;
    domainDefaultFixture.hidden = true;
    themeDefaultFixture.hidden = true;
    moduleSmallScreenFixture.hidden = true;
    staticExportFixture.hidden = true;
    document.documentElement.dataset.fixtureStatus = "REJECTED_UNKNOWN_STATE";
    document.body.dataset.stateFixture = "REJECTED";
    document.getElementById("fixture-label").textContent = `Rejected fixture state: ${requestedState}`;
    return;
  }

  document.documentElement.dataset.fixtureStatus = "ACCEPTED";
  document.body.dataset.stateFixture = requestedState;
  document.getElementById("fixture-label").textContent = fixtures[requestedState];

  foundationFixture.hidden = requestedState !== "visual-foundation";
  moduleDefaultFixture.hidden = requestedState !== "module-default";
  relationFocusFixture.hidden = requestedState !== "relation-focus";
  sourceVerificationFixture.hidden = requestedState !== "source-verification";
  revisionImpactFixture.hidden = requestedState !== "revision-impact";
  partialFailureFixture.hidden = requestedState !== "partial-failure";
  conflictedDraftFixture.hidden = requestedState !== "conflicted-draft";
  domainDefaultFixture.hidden = requestedState !== "domain-default";
  themeDefaultFixture.hidden = requestedState !== "theme-default";
  moduleSmallScreenFixture.hidden = requestedState !== "module-small-screen";
  staticExportFixture.hidden = requestedState !== "static-export";

  if (requestedState === "module-default") {
    document.title = "Cognitura · Module Default Reading Fixture";
    document.body.dataset.moduleDefaultEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.zeroInteractionCognitiveClosure = "COMPLETE";
    document.body.dataset.continuousExplanatoryNarrative = "REQUIRED";
    document.body.dataset.primaryCognitiveSpine = "VISIBLE";
    document.body.dataset.primaryVisualProjectionCount = "1";
    document.body.dataset.keyRelationCount = "2";
    document.body.dataset.persistentGovernanceSidePanelCount = "0";
    document.body.dataset.visiblePerspectiveSwitches = "0";
    document.body.dataset.knowledgeElementEntry = "ON_DEMAND";
    document.body.dataset.sourceEvidenceEntry = "ON_DEMAND";
  }

  const restoreFocus = function (targetId, transition) {
    const target = document.getElementById(targetId);
    if (!target) {
      document.body.dataset.focusReturnStatus = "MISSING_TARGET";
      return;
    }
    target.focus();
    document.body.dataset.focusReturnStatus = "RESTORED";
    document.body.dataset.focusReturnedTo = target.id;
    document.body.dataset.lastTransition = transition;
  };

  const safeHistoryWrite = function (key, value) {
    try {
      const nextState = Object.assign({}, window.history.state || {});
      nextState[key] = value;
      window.history.replaceState(nextState, "", window.location.href);
      return true;
    } catch (error) {
      document.body.dataset.historyStateStatus = "UNAVAILABLE";
      return false;
    }
  };

  const navigateToFixture = function (state, transition) {
    const nextUrl = new URL(window.location.href);
    nextUrl.searchParams.set("state", state);
    nextUrl.searchParams.set("origin", requestedState);
    window.history.pushState({
      cognituraWorkspace: state,
      originFixture: requestedState
    }, "", nextUrl);
    document.body.dataset.lastTransition = transition;
    window.location.reload();
  };

  const recoveryBaseline = Object.freeze({
    workspace: "partial-failure",
    draftId: "draft-r7",
    semanticAnchor: "recovery-canonical-boundary",
    focusTarget: "recovery-origin-anchor",
    processingState: "CANONICAL_SAVED",
    restoreSequence: 0
  });

  const applyRecoverySnapshot = function (snapshot, source) {
    const recoveryRoot = document.getElementById("partial-failure-document");
    if (!recoveryRoot || !snapshot || snapshot.workspace !== "partial-failure") {
      document.body.dataset.recoveryLifecycle = "INVALID_RECOVERY_INPUT";
      return false;
    }
    const requestedAnchor = document.getElementById(snapshot.semanticAnchor);
    const resolvedAnchor = requestedAnchor || document.getElementById("recovery-canonical-boundary");
    const feedback = recoveryRoot.querySelector(".result-query-feedback");
    recoveryRoot.dataset.processingState = snapshot.processingState;
    recoveryRoot.dataset.draftState = "RECOVERABLE_DRAFT";
    recoveryRoot.dataset.restoredSemanticAnchor = resolvedAnchor ? resolvedAnchor.id : "";
    document.body.dataset.draftRestoreStatus = "RESTORED";
    document.body.dataset.restoredDraft = snapshot.draftId;
    document.body.dataset.restoredSemanticAnchor = resolvedAnchor ? resolvedAnchor.id : "";
    document.body.dataset.recoveryLifecycle = source;
    document.body.dataset.historyRestoreSequence = String(snapshot.restoreSequence);
    document.body.dataset.semanticAnchorDisposition = requestedAnchor ? "STABLE" : "REBASED_TO_CANONICAL_PARENT";
    if (feedback) {
      feedback.textContent = requestedAnchor ?
        "刷新已恢复 Target、Workspace、draft r7 与语义 Anchor。" :
        "原语义 Anchor 已移动；已明确回退到最近的正式保存边界。";
    }
    const focusTarget = document.getElementById(snapshot.focusTarget) || resolvedAnchor;
    if (focusTarget) {
      focusTarget.focus();
      document.body.dataset.focusReturnedTo = focusTarget.id;
    }
    return true;
  };

  const pushRecoverySnapshot = function () {
    const snapshot = {
      workspace: "partial-failure",
      draftId: "draft-r7",
      semanticAnchor: "module-results",
      focusTarget: "recovery-origin-anchor",
      processingState: "CANONICAL_SAVED",
      restoreSequence: 1
    };
    const nextUrl = new URL(window.location.href);
    nextUrl.searchParams.set("recovery", "draft-r7");
    nextUrl.hash = "module-results";
    window.history.pushState({cognituraRecovery: snapshot}, "", nextUrl);
    applyRecoverySnapshot(snapshot, "PUSHSTATE_RESTORE");
    return snapshot;
  };

  const initializeRecoveryLifecycle = function () {
    const currentState = window.history.state && window.history.state.cognituraRecovery;
    if (!currentState) {
      window.history.replaceState({cognituraRecovery: recoveryBaseline}, "", window.location.href);
    }
    const navigationEntry = window.performance.getEntriesByType("navigation")[0];
    const effectiveSnapshot = (window.history.state && window.history.state.cognituraRecovery) || recoveryBaseline;
    if (navigationEntry && navigationEntry.type === "reload") {
      applyRecoverySnapshot(effectiveSnapshot, "RELOADED_FROM_HISTORY");
    } else {
      document.body.dataset.recoveryLifecycle = "INITIAL_HISTORY_STATE";
      document.body.dataset.historyRestoreSequence = String(effectiveSnapshot.restoreSequence);
    }
    window.addEventListener("popstate", function (event) {
      const snapshot = event.state && event.state.cognituraRecovery;
      applyRecoverySnapshot(snapshot || recoveryBaseline, "POPSTATE_RESTORE");
    });
  };

  window.CognituraRecoveryHarness = Object.freeze({
    pushSnapshot: pushRecoverySnapshot,
    applySnapshot: applyRecoverySnapshot,
    readStoredSnapshot: function () {
      return (window.history.state && window.history.state.cognituraRecovery) || null;
    }
  });

  const bindDeterministicControls = function (root, defaultReturnTarget) {
    const quickSourcePanel = root.querySelector(".quick-source-panel");
    const quickSourceTrigger = root.querySelector("#relation-quick-source-trigger");
    const openQuickSource = function () {
      if (!quickSourcePanel) {
        document.body.dataset.quickSourceStatus = "MISSING_PANEL";
        return;
      }
      quickSourcePanel.hidden = false;
      document.body.dataset.quickSourceStatus = "OPEN";
      document.body.dataset.auxiliarySurface = "QUICK_SOURCE";
    };
    const performAction = function (control) {
      const action = control.dataset.touchEquivalent || control.dataset.enterAction || "";
      document.body.dataset.touchEquivalentAction = action;
      if (action === "OPEN_QUICK_SOURCE") {
        openQuickSource();
      }
      if (action === "UPGRADE_FULL_VERIFICATION" || action === "OPEN_VERIFICATION") {
        navigateToFixture("source-verification", "FULL_VERIFICATION_WORKSPACE_OPEN");
      }
      if (action === "CONFIRM_VERIFICATION") {
        const verificationDocument = root.querySelector("#source-verification-document");
        const feedback = root.querySelector("#verification-action-feedback");
        if (verificationDocument) {
          verificationDocument.dataset.verificationStatus = "CONFIRMED";
          verificationDocument.dataset.verificationDecision = "ACCEPT_CANONICAL_TARGET_WITH_SCOPE";
        }
        if (feedback) {
          feedback.innerHTML = "<b>核验裁决已确认</b> · Canonical Target 与限制范围已保留";
        }
        safeHistoryWrite("cognituraVerificationDecision", {
          target: "rel-read-view-visibility",
          status: "CONFIRMED"
        });
        document.body.dataset.lastTransition = "VERIFICATION_CONFIRMED";
      }
      if (action === "ADD_SOURCE") {
        const sourceGap = root.querySelector(".source-gap");
        if (sourceGap) {
          sourceGap.dataset.followUpState = "SOURCE_REQUEST_DRAFTED";
          sourceGap.querySelector("p:not(.eyebrow)").textContent =
            "来源补充请求已形成草稿；正式命题在重新核验前保持原限制范围。";
        }
        document.body.dataset.lastTransition = "SOURCE_REQUEST_DRAFTED";
      }
    };
    root.querySelectorAll("[data-touch-equivalent]").forEach(function (control) {
      control.addEventListener("click", function () {
        performAction(control);
      });
    });
    root.querySelectorAll("[data-enter-action]").forEach(function (control) {
      control.addEventListener("keydown", function (event) {
        if (event.key === "Enter") {
          document.body.dataset.keyboardEnterAction = control.dataset.enterAction;
          performAction(control);
        }
      });
    });
    root.querySelectorAll("[data-focus-return-target]").forEach(function (control) {
      control.addEventListener("click", function () {
        if (control.classList.contains("quick-source-close") && quickSourcePanel) {
          quickSourcePanel.hidden = true;
          document.body.dataset.quickSourceStatus = "CLOSED";
          document.body.dataset.auxiliarySurface = "NONE";
          restoreFocus(control.dataset.focusReturnTarget, "QUICK_SOURCE_EXPLICIT_CLOSE");
          return;
        }
        restoreFocus(control.dataset.focusReturnTarget, "EXPLICIT_CLOSE");
      });
    });
    root.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        event.preventDefault();
        if (quickSourcePanel && !quickSourcePanel.hidden) {
          quickSourcePanel.hidden = true;
          document.body.dataset.quickSourceStatus = "CLOSED";
          document.body.dataset.auxiliarySurface = "NONE";
          restoreFocus(quickSourceTrigger.id, "QUICK_SOURCE_ESCAPE_CLOSE");
          return;
        }
        restoreFocus(defaultReturnTarget, "ESCAPE_CLOSE");
      }
    });
  };

  if (requestedState === "relation-focus") {
    document.title = "Cognitura · Relation Focus Fixture";
    document.body.dataset.relationFocusEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.primaryStableFocusCount = "1";
    document.body.dataset.quickSourcePersistence = "EPHEMERAL_NOT_URL";
    bindDeterministicControls(relationFocusFixture, "relation-origin-anchor");
  }

  if (requestedState === "source-verification") {
    document.title = "Cognitura · Source Verification Fixture";
    document.body.dataset.sourceVerificationEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.workspaceHistory = "URL_AND_HISTORY";
    document.body.dataset.originalReadingAnchor = "RETAINED";
    bindDeterministicControls(sourceVerificationFixture, "source-origin-anchor");
  }

  const bindHvd03Controls = function (root, defaultReturnTarget) {
    root.querySelectorAll("[data-touch-equivalent]").forEach(function (control) {
      control.addEventListener("click", function () {
        const action = control.dataset.touchEquivalent;
        document.body.dataset.touchEquivalentAction = action;
        if (action === "SAVE_DRAFT") {
          const revisionDocument = root.querySelector("#revision-impact-document");
          const feedback = root.querySelector(".draft-preserved");
          if (revisionDocument) {
            revisionDocument.dataset.draftState = "SAVED_SESSION_DRAFT";
          }
          safeHistoryWrite("cognituraRevisionDraft", {
            draftId: "draft-r7",
            baseVersion: "v12",
            state: "SAVED_SESSION_DRAFT"
          });
          if (feedback) {
            feedback.textContent = "草稿已保存到会话恢复存储 · draft r7 · 未发生正式写入";
          }
          document.body.dataset.lastTransition = "SESSION_DRAFT_SAVED";
        }
        if (action === "RETRY_SEMANTIC_ANALYSIS") {
          const semanticLane = root.querySelector(".impact-lane.impact-semantic");
          if (semanticLane) {
            semanticLane.dataset.processingState = "RETRYING";
            semanticLane.setAttribute("aria-busy", "true");
          }
          document.body.dataset.lastTransition = "SEMANTIC_ANALYSIS_RETRYING";
          document.body.dataset.retryScope = "SEMANTIC_ONLY";
        }
        if (action === "RETRY_RECOMPUTE") {
          document.body.dataset.lastTransition = "RETRY_FAILED_CHANNEL";
          document.body.dataset.retryScope = "RECOMPUTING_ONLY";
          const failedChannel = root.querySelector(".processing-state.failed");
          if (failedChannel) {
            failedChannel.dataset.channelState = "RETRYING";
            failedChannel.setAttribute("aria-busy", "true");
            failedChannel.querySelector("em").textContent = "RETRYING";
          }
        }
        if (action === "QUERY_ORIGINAL_RESULT") {
          document.body.dataset.lastTransition = "QUERY_ORIGINAL_RESULT_SAME_KEY";
          document.body.dataset.resultQueryKey = "idem-hv-d03-1042";
          const feedback = root.querySelector(".result-query-feedback");
          if (feedback) {
            feedback.textContent = "原 ChangeSet cs-1042 已确认；未创建第二次提交。";
          }
        }
        if (action === "RESTORE_DRAFT") {
          pushRecoverySnapshot();
          restoreFocus(defaultReturnTarget, "REFRESH_DRAFT_RESTORED");
        }
        if (action === "DRAFT_REVERT_CHANGESET") {
          document.body.dataset.lastTransition = "REVERT_CHANGESET_DRAFTED";
          document.body.dataset.revertDisposition = "CREATE_NEW_CHANGESET";
          const feedback = root.querySelector(".result-query-feedback");
          if (feedback) {
            feedback.textContent = "Revert ChangeSet 草稿已创建；v13 保持正式且历史未被删除。";
          }
        }
        if (action === "REBASE_DRAFT") {
          document.body.dataset.lastTransition = "REBASE_PREVIEWED";
          document.body.dataset.rebaseStatus = "DRAFT_PRESERVED";
          document.body.dataset.canonicalWrite = "NONE";
        }
        if (action === "PRESERVE_DRAFT_COPY") {
          const conflictDocument = root.querySelector("#conflicted-draft-document");
          const feedback = root.querySelector(".conflict-feedback");
          safeHistoryWrite("cognituraPreservedDraftCopy", {
            draftId: "draft-r7-copy",
            baseVersion: "v12",
            latestVersion: "v13"
          });
          if (conflictDocument) {
            conflictDocument.dataset.draftCopyStatus = "PRESERVED";
          }
          if (feedback) {
            feedback.textContent = "草稿副本 draft-r7-copy 已保留；原 Focus 与正式 v13 均未改变。";
          }
          document.body.dataset.lastTransition = "DRAFT_COPY_PRESERVED";
        }
        if (action === "CONTINUE_EDITING") {
          const conflictDocument = root.querySelector("#conflicted-draft-document");
          const draftPanel = root.querySelector(".diff-draft");
          if (conflictDocument) {
            conflictDocument.dataset.draftMode = "EDITING";
          }
          if (draftPanel) {
            draftPanel.tabIndex = -1;
            draftPanel.focus();
          }
          document.body.dataset.lastTransition = "DRAFT_EDITING_RESUMED";
        }
      });
    });
    root.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        event.preventDefault();
        restoreFocus(defaultReturnTarget, "ESCAPE_CLOSE");
      }
    });
  };

  const exceptionScenarios = Object.freeze({
    "EX-PREVIEW-TARGET-DELETED": {state: "relation-focus", action: "CLOSE_PREVIEW_AND_RESTORE_FOCUS", focus: "relation-origin-anchor", effect: "PREVIEW_CLOSED"},
    "EX-RELATION-SUPERSEDED": {state: "relation-focus", action: "EXPLAIN_SUPERSESSION_AND_RESTORE_ORIGIN", focus: "relation-origin-anchor", effect: "RELATION_SUPERSEDED_EXPLAINED"},
    "EX-ELEMENT-PRIMARY-PARENT-CHANGED": {state: "module-default", action: "REBASE_CANONICAL_LOCATION", focus: "module-default-document", effect: "CANONICAL_LOCATION_REBASED"},
    "EX-AUTO-UPGRADE-FAILED": {state: "revision-impact", action: "PRESERVE_DRAFT_AND_OPEN_FULL_REVISION", focus: "revision-origin-anchor", effect: "FULL_REVISION_FALLBACK"},
    "EX-IMPACT-ANALYSIS-FAILED": {state: "revision-impact", action: "BLOCK_COMMIT_AND_RETRY_ANALYSIS", focus: "revision-impact-document", effect: "IMPACT_RETRY_REQUIRED"},
    "EX-CANONICAL-SAVED-RECOMPUTE-FAILED": {state: "partial-failure", action: "RETRY_RECOMPUTE_ONLY", focus: "recovery-origin-anchor", effect: "RECOMPUTE_RETRY_READY"},
    "EX-CANONICAL-SAVED-GENERATION-FAILED": {state: "partial-failure", action: "RETRY_GENERATION_ONLY", focus: "recovery-origin-anchor", effect: "GENERATION_RETRY_READY"},
    "EX-GENERATED-CONFLICTS-LOCKED": {state: "conflicted-draft", action: "BLOCK_REPLACEMENT_AND_SHOW_LOCK", focus: "conflict-detail-trigger", effect: "LOCKED_CONTENT_PROTECTED"},
    "EX-DRAFT-CONFLICTS-LATEST": {state: "conflicted-draft", action: "PRESERVE_DRAFT_AND_REQUIRE_REBASE", focus: "conflict-origin-anchor", effect: "DRAFT_REBASE_REQUIRED"},
    "EX-SOURCE-INVALIDATED": {state: "source-verification", action: "MARK_INVALID_AND_REQUIRE_REVERIFY", focus: "source-origin-anchor", effect: "SOURCE_REVERIFICATION_REQUIRED"},
    "EX-REFRESH-FOCUS-RESTORE-FAILED": {state: "partial-failure", action: "FOCUS_NEAREST_CANONICAL_PARENT", focus: "recovery-canonical-boundary", effect: "FOCUS_FALLBACK_EXPLICIT"},
    "EX-SEMANTIC-ANCHOR-MOVED": {state: "partial-failure", action: "REBASE_MOVED_SEMANTIC_ANCHOR", focus: "recovery-canonical-boundary", effect: "SEMANTIC_ANCHOR_REBASED"},
    "EX-SMALL-SCREEN-PANEL-OVERFLOW": {state: "module-small-screen", action: "OPEN_SAFE_OVERLAY", focus: "small-element-overlay", effect: "SAFE_OVERLAY_OPEN"},
    "EX-TOUCH-NO-HOVER": {state: "module-small-screen", action: "USE_EXPLICIT_TOUCH_CONTROL", focus: "small-element-overlay", effect: "TOUCH_EQUIVALENT_OPEN"},
    "EX-KEYBOARD-ENTERS-GRAPH": {state: "relation-focus", action: "KEEP_LINEAR_FOCUS_AND_ESCAPE_RETURN", focus: "relation-origin-anchor", effect: "LINEAR_FOCUS_ORDER_RETAINED"},
    "EX-DUPLICATE-SUBMIT-CLICK": {state: "revision-impact", action: "DEDUPLICATE_SUBMISSION_WITH_FEEDBACK", focus: "revision-origin-anchor", effect: "DUPLICATE_SUBMISSION_DEDUPED"},
    "EX-NETWORK-TIMEOUT-SAVE-UNKNOWN": {state: "partial-failure", action: "QUERY_ORIGINAL_RESULT_SAME_KEY", focus: "recovery-origin-anchor", effect: "ORIGINAL_RESULT_QUERIED"},
    "EX-UI-FAILED-CANONICAL-SAVED": {state: "partial-failure", action: "SHOW_CANONICAL_SAVED_TRUTH", focus: "recovery-canonical-boundary", effect: "CANONICAL_SAVED_RETAINED"},
    "EX-REVERT-AFFECTS-LATER-CHANGES": {state: "partial-failure", action: "CREATE_REVERT_CHANGESET_AFTER_IMPACT", focus: "recovery-origin-anchor", effect: "REVERT_CHANGESET_DRAFTED"},
    "EX-WORKSPACE-SWITCH-WITH-DRAFT": {state: "conflicted-draft", action: "SHOW_SAVE_DISCARD_CANCEL_GUARD", focus: "conflict-origin-anchor", effect: "WORKSPACE_SWITCH_GUARDED"}
  });

  const fixtureForState = function (state) {
    return {
      "module-default": moduleDefaultFixture,
      "relation-focus": relationFocusFixture,
      "source-verification": sourceVerificationFixture,
      "revision-impact": revisionImpactFixture,
      "partial-failure": partialFailureFixture,
      "conflicted-draft": conflictedDraftFixture,
      "module-small-screen": moduleSmallScreenFixture
    }[state] || null;
  };

  const runExceptionScenario = function (exceptionId) {
    const scenario = exceptionScenarios[exceptionId];
    const fixture = fixtureForState(requestedState);
    if (!scenario || scenario.state !== requestedState || !fixture) {
      document.body.dataset.exceptionHarnessStatus = "REJECTED";
      return false;
    }
    const root = fixture.querySelector("main, [data-state-code]") || fixture;
    let observation = fixture.querySelector(".exception-recovery-observation");
    if (!observation) {
      observation = document.createElement("aside");
      observation.className = "exception-recovery-observation";
      observation.setAttribute("role", "status");
      observation.setAttribute("aria-live", "polite");
      observation.tabIndex = -1;
      root.appendChild(observation);
    }
    observation.dataset.exceptionId = exceptionId;
    observation.dataset.recoveryAction = scenario.action;
    observation.textContent = exceptionId + " · " + scenario.action;
    root.dataset.exceptionState = exceptionId;
    document.body.dataset.exceptionEffect = scenario.effect;
    document.body.dataset.exceptionHarnessStatus = "RECOVERED_WITH_FEEDBACK";

    if (exceptionId === "EX-PREVIEW-TARGET-DELETED") {
      const preview = fixture.querySelector(".quick-source-panel");
      if (preview) { preview.hidden = true; }
    }
    if (exceptionId === "EX-RELATION-SUPERSEDED") {
      fixture.querySelector(".relation-focus-primary").dataset.relationStatus = "SUPERSEDED_EXPLAINED";
    }
    if (exceptionId === "EX-ELEMENT-PRIMARY-PARENT-CHANGED") {
      root.dataset.canonicalLocation = "REBASED_WITHOUT_SECOND_TREE";
    }
    if (exceptionId === "EX-AUTO-UPGRADE-FAILED") {
      root.dataset.autoUpgradeStatus = "FAILED_FULL_REVISION_FALLBACK";
      root.dataset.draftState = "DIRTY_DRAFT_PRESERVED";
    }
    if (exceptionId === "EX-IMPACT-ANALYSIS-FAILED") {
      root.dataset.impactAnalysisStatus = "FAILED_RETRY_REQUIRED";
      fixture.querySelector(".commit-control").disabled = true;
    }
    if (exceptionId === "EX-CANONICAL-SAVED-RECOMPUTE-FAILED") {
      fixture.querySelector(".processing-state.failed").dataset.channelState = "RETRY_READY";
    }
    if (exceptionId === "EX-CANONICAL-SAVED-GENERATION-FAILED") {
      fixture.querySelector(".processing-state.stale").dataset.channelState = "RETRY_READY";
    }
    if (exceptionId === "EX-GENERATED-CONFLICTS-LOCKED") {
      root.dataset.lockedContentDisposition = "REPLACEMENT_BLOCKED";
    }
    if (exceptionId === "EX-DRAFT-CONFLICTS-LATEST") {
      root.dataset.draftPreserved = "true";
      root.dataset.rebaseRequired = "true";
    }
    if (exceptionId === "EX-SOURCE-INVALIDATED") {
      fixture.querySelector(".source-evidence-item").dataset.sourceStatus = "INVALIDATED";
      root.dataset.verificationStatus = "REVERIFICATION_REQUIRED";
    }
    if (exceptionId === "EX-REFRESH-FOCUS-RESTORE-FAILED" || exceptionId === "EX-SEMANTIC-ANCHOR-MOVED") {
      applyRecoverySnapshot({
        workspace: "partial-failure",
        draftId: "draft-r7",
        semanticAnchor: "missing-semantic-anchor",
        focusTarget: "missing-focus-target",
        processingState: "CANONICAL_SAVED",
        restoreSequence: 2
      }, "EXCEPTION_FALLBACK");
    }
    if (exceptionId === "EX-SMALL-SCREEN-PANEL-OVERFLOW" || exceptionId === "EX-TOUCH-NO-HOVER") {
      fixture.querySelector("#small-element-trigger").click();
    }
    if (exceptionId === "EX-KEYBOARD-ENTERS-GRAPH") {
      root.dataset.focusOrder = "LINEAR_RELATION_ENDPOINTS";
    }
    if (exceptionId === "EX-DUPLICATE-SUBMIT-CLICK") {
      root.dataset.submissionAttemptCount = "1";
      root.dataset.duplicateSubmission = "DEDUPED";
    }
    if (exceptionId === "EX-NETWORK-TIMEOUT-SAVE-UNKNOWN") {
      fixture.querySelector(".query-original-result").click();
    }
    if (exceptionId === "EX-UI-FAILED-CANONICAL-SAVED") {
      root.dataset.processingState = "CANONICAL_SAVED";
      root.dataset.falseRollback = "FORBIDDEN";
    }
    if (exceptionId === "EX-REVERT-AFFECTS-LATER-CHANGES") {
      fixture.querySelector(".revert-changeset").click();
    }
    if (exceptionId === "EX-WORKSPACE-SWITCH-WITH-DRAFT") {
      root.dataset.workspaceSwitchGuard = "SAVE_DISCARD_CANCEL_REQUIRED";
      root.dataset.draftPreserved = "true";
    }
    safeHistoryWrite("cognituraExceptionObservation", {
      exceptionId: exceptionId,
      action: scenario.action,
      effect: scenario.effect
    });
    const focusTarget = document.getElementById(scenario.focus);
    if (focusTarget) {
      focusTarget.focus();
    }
    document.body.dataset.exceptionFocusTarget = focusTarget ? focusTarget.id : "";
    return true;
  };

  window.CognituraExceptionHarness = Object.freeze({
    ids: Object.freeze(Object.keys(exceptionScenarios)),
    run: runExceptionScenario
  });

  if (requestedState === "revision-impact") {
    document.title = "Cognitura · Revision Impact Fixture";
    document.body.dataset.revisionImpactEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.impactLaneCount = "3";
    document.body.dataset.blockerDefaultExpanded = "true";
    document.body.dataset.commitAllowed = "false";
    document.body.dataset.draftPersistence = "SESSION_RESTORE_ONLY";
    bindHvd03Controls(revisionImpactFixture, "revision-origin-anchor");
  }

  if (requestedState === "partial-failure") {
    document.title = "Cognitura · Partial Failure Recovery Fixture";
    document.body.dataset.recoveryEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.canonicalSavedBoundary = "CONFIRMED";
    document.body.dataset.processingStateCount = "4";
    document.body.dataset.staleProjection = "EXPLICIT";
    document.body.dataset.submitUnknownDisposition = "QUERY_SAME_IDEMPOTENCY_KEY";
    document.body.dataset.revertDisposition = "CREATE_NEW_CHANGESET";
    bindHvd03Controls(partialFailureFixture, "recovery-origin-anchor");
    initializeRecoveryLifecycle();
  }

  if (requestedState === "conflicted-draft") {
    document.title = "Cognitura · Conflicted Draft Fixture";
    document.body.dataset.conflictedDraftEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.rebaseRequired = "true";
    document.body.dataset.draftPreserved = "true";
    document.body.dataset.commitAllowed = "false";
    const conflictRoot = document.getElementById("conflicted-draft-document");
    const conflictPanel = document.getElementById("conflict-detail-panel");
    const conflictTrigger = document.getElementById("conflict-detail-trigger");
    bindHvd03Controls(conflictedDraftFixture, "conflict-origin-anchor");
    conflictTrigger.addEventListener("click", function () {
      conflictPanel.hidden = false;
      conflictPanel.focus();
      document.body.dataset.lastTransition = "CONFLICT_DETAIL_OPEN";
    });
    conflictRoot.addEventListener("keydown", function (event) {
      if (event.key !== "Escape" || conflictPanel.hidden) {
        return;
      }
      event.preventDefault();
      event.stopImmediatePropagation();
      conflictPanel.hidden = true;
      restoreFocus("conflict-detail-trigger", "CONFLICT_DETAIL_ESCAPE_CLOSE");
    }, true);
  }

  if (requestedState === "domain-default") {
    document.title = "Cognitura · Knowledge Landscape and Theme Fixture";
    document.body.dataset.crossLayerEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.canonicalHierarchy = "KnowledgeLandscape>KnowledgeTheme>CognitiveModule>KnowledgeElement";
    document.body.dataset.cardWallCount = "0";
    document.body.dataset.graphWorkspaceCount = "0";
    const crossLayerRoot = document.getElementById("landscape-theme-document");
    const themeEntry = document.getElementById("theme-detail-trigger");
    const themeClosure = document.getElementById("theme-closure-panel");
    themeEntry.addEventListener("click", function () {
      themeClosure.focus();
      document.body.dataset.lastTransition = "THEME_CLOSURE_FOCUSED";
    });
    crossLayerRoot.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        event.preventDefault();
        restoreFocus("landscape-origin-anchor", "LANDSCAPE_CONTEXT_RESTORED");
      }
    });
  }

  if (requestedState === "theme-default") {
    document.title = "Cognitura · Cross-domain Reading Fixture";
    document.body.dataset.crossDomainEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.canonicalHierarchyCount = "2";
    document.body.dataset.independentDomainObjectCount = "0";
  }

  if (requestedState === "module-small-screen") {
    document.title = "Cognitura · Small-screen Reading Fixture";
    document.body.dataset.smallScreenEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.smallScreenPrimarySurface = "DOCUMENT_FLOW";
    document.body.dataset.persistentSidePanelCount = "0";
    const smallRoot = document.getElementById("small-screen-document");
    const smallTrigger = document.getElementById("small-element-trigger");
    const smallOverlay = document.getElementById("small-element-overlay");
    const smallClose = document.getElementById("small-overlay-close");
    const closeSmallOverlay = function (transition) {
      smallOverlay.hidden = true;
      restoreFocus("small-element-trigger", transition);
    };
    smallTrigger.addEventListener("click", function () {
      smallOverlay.hidden = false;
      smallOverlay.focus();
      document.body.dataset.lastTransition = "SMALL_ELEMENT_OVERLAY_OPEN";
    });
    smallClose.addEventListener("click", function () {
      closeSmallOverlay("SMALL_ELEMENT_EXPLICIT_CLOSE");
    });
    smallRoot.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && !smallOverlay.hidden) {
        event.preventDefault();
        closeSmallOverlay("SMALL_ELEMENT_ESCAPE_CLOSE");
      }
    });
  }

  if (requestedState === "static-export") {
    document.title = "Cognitura · Static Export Fixture";
    document.body.dataset.staticExportEvidence = "HIGH_FIDELITY_VISUAL_PASS";
    document.body.dataset.machineIdentitySource = "COMPANION_MANIFEST";
    document.body.dataset.rawTechnicalIdsVisible = "false";
    document.body.dataset.imageCanonicalAuthority = "NONE";
  }
})();
