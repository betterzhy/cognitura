(function () {
  "use strict";

  const fixtures = Object.freeze({
    "visual-foundation": "Visual foundation",
    "module-default": "Module default reading · reserved for HV-D01",
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

  if (!Object.prototype.hasOwnProperty.call(fixtures, requestedState)) {
    document.documentElement.dataset.fixtureStatus = "REJECTED_UNKNOWN_STATE";
    document.body.dataset.stateFixture = "REJECTED";
    document.getElementById("fixture-label").textContent = `Rejected fixture state: ${requestedState}`;
    return;
  }

  document.documentElement.dataset.fixtureStatus = "ACCEPTED";
  document.body.dataset.stateFixture = requestedState;
  document.getElementById("fixture-label").textContent = fixtures[requestedState];
})();
