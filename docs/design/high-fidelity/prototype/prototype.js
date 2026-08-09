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
    root.querySelectorAll("[data-touch-equivalent]").forEach(function (control) {
      control.addEventListener("click", function () {
        document.body.dataset.touchEquivalentAction = control.dataset.touchEquivalent;
        if (control.dataset.touchEquivalent === "OPEN_QUICK_SOURCE") {
          openQuickSource();
        }
      });
    });
    root.querySelectorAll("[data-enter-action]").forEach(function (control) {
      control.addEventListener("keydown", function (event) {
        if (event.key === "Enter") {
          document.body.dataset.keyboardEnterAction = control.dataset.enterAction;
          if (control.dataset.enterAction === "OPEN_QUICK_SOURCE") {
            openQuickSource();
          }
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
        document.body.dataset.touchEquivalentAction = control.dataset.touchEquivalent;
        if (control.classList.contains("retry-recompute")) {
          document.body.dataset.lastTransition = "RETRY_FAILED_CHANNEL";
          document.body.dataset.retryScope = "RECOMPUTING_ONLY";
        }
        if (control.classList.contains("query-original-result")) {
          document.body.dataset.lastTransition = "QUERY_ORIGINAL_RESULT_SAME_KEY";
          document.body.dataset.resultQueryKey = "idem-hv-d03-1042";
          const feedback = root.querySelector(".result-query-feedback");
          if (feedback) {
            feedback.textContent = "原 ChangeSet cs-1042 已确认；未创建第二次提交。";
          }
        }
        if (control.classList.contains("restore-draft")) {
          document.body.dataset.draftRestoreStatus = "RESTORED";
          document.body.dataset.restoredDraft = "draft-r7";
          document.body.dataset.restoredSemanticAnchor = "module-results";
          restoreFocus(defaultReturnTarget, "REFRESH_DRAFT_RESTORED");
        }
        if (control.classList.contains("revert-changeset")) {
          document.body.dataset.lastTransition = "REVERT_CHANGESET_DRAFTED";
          document.body.dataset.revertDisposition = "CREATE_NEW_CHANGESET";
        }
        if (control.classList.contains("rebase-draft")) {
          document.body.dataset.lastTransition = "REBASE_PREVIEWED";
          document.body.dataset.rebaseStatus = "DRAFT_PRESERVED";
          document.body.dataset.canonicalWrite = "NONE";
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
