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
  const selectedState = Object.prototype.hasOwnProperty.call(fixtures, requestedState)
    ? requestedState
    : "visual-foundation";

  document.body.dataset.stateFixture = selectedState;
  document.getElementById("fixture-label").textContent = fixtures[selectedState];
})();
