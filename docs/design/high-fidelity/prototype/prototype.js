(function () {
  "use strict";

  const fixtures = Object.freeze({
    "visual-foundation": "Visual foundation",
    "module-default": "Module default reading · HV-D01 evidence",
    "relation-focus": "Relation focus · HV-D02 evidence",
    "source-verification": "Source verification · HV-D02 evidence",
    "revision-impact": "Revision impact · reserved for HV-D03",
    "partial-failure": "Partial failure · reserved for HV-D03",
    "conflicted-draft": "Conflicted draft · reserved for HV-D03",
    "domain-default": "Knowledge Landscape · reserved for HV-D04",
    "theme-default": "Knowledge Theme · reserved for HV-D04",
    "module-small-screen": "Small-screen Module · reserved for HV-D04",
    "static-export": "Static export · reserved for HV-D04"
  });

  const query = new URLSearchParams(window.location.search);
  const requestedState = query.get("state") || "visual-foundation";
  const foundationFixture = document.getElementById("visual-foundation-fixture");
  const moduleDefaultFixture = document.getElementById("module-default-fixture");
  const relationFocusFixture = document.getElementById("relation-focus-fixture");
  const sourceVerificationFixture = document.getElementById("source-verification-fixture");

  if (!Object.prototype.hasOwnProperty.call(fixtures, requestedState)) {
    foundationFixture.hidden = true;
    moduleDefaultFixture.hidden = true;
    relationFocusFixture.hidden = true;
    sourceVerificationFixture.hidden = true;
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
})();
