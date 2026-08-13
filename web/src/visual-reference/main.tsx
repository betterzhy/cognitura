import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import "../styles/cognitura.css";
import { VisualReference } from "./VisualReference";
import "./visual-reference.css";

createRoot(document.getElementById("visual-reference-root")!).render(
  <StrictMode>
    <VisualReference />
  </StrictMode>,
);
