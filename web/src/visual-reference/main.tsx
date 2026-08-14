import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import "../styles/cognitura.css";
import { findVisualReferenceRoot, VisualReference } from "./VisualReference";
import "./visual-reference.css";

createRoot(findVisualReferenceRoot(document.body)).render(
  <StrictMode>
    <VisualReference />
  </StrictMode>,
);
