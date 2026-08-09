(function () {
  "use strict";

  const fixtures = Object.freeze({
    "visual-foundation": "Visual foundation",
    "module-default": "Module default reading · HV-D01 evidence",
    "relation-focus": "Relation focus · reserved for HV-D02",
    "source-verification": "Source verification · reserved for HV-D02",
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

  if (!Object.prototype.hasOwnProperty.call(fixtures, requestedState)) {
    foundationFixture.hidden = true;
    moduleDefaultFixture.hidden = true;
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
})();
