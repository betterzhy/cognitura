import { useEffect } from "react";

import { ModuleDefaultReading } from "../modules/module-reading/ModuleDefaultReading";
import {
  visualReferenceModule,
  visualReferenceRenderer,
} from "./module-default-reading.fixture";

export function findVisualReferenceRoot(root: ParentNode) {
  const visualReferenceRoot = root.querySelector<HTMLElement>(
    '#visual-reference-root[data-visual-entry="reference-only"]',
  );
  if (visualReferenceRoot === null) {
    throw new Error("VISUAL_REFERENCE_ROOT_MISSING");
  }
  return visualReferenceRoot;
}

export function VisualReference() {
  useEffect(() => {
    document.documentElement.dataset.visualReferenceReady = "true";
    return () => {
      delete document.documentElement.dataset.visualReferenceReady;
    };
  }, []);

  return (
    <div
      className="visual-reference cka-visual-root"
      data-product-route="false"
      data-visual-reference="SYNTHETIC_VISUAL_REFERENCE_ONLY"
    >
      <header className="visual-reference__topbar">
        <div className="visual-reference__brand-mark" aria-hidden="true">
          C
        </div>
        <div>
          <strong>Cognitura</strong>
          <span>个人认知结构工作台</span>
        </div>
        <span className="visual-reference__fixture-label">
          视觉参考 · 非产品路由
        </span>
      </header>
      <div className="visual-reference__canvas">
        <nav aria-label="知识路径" className="visual-reference__path">
          数据库系统 <span aria-hidden="true">/</span> 并发控制{" "}
          <span aria-hidden="true">/</span> MVCC
        </nav>
        <ModuleDefaultReading
          module={visualReferenceModule}
          rendererInput={visualReferenceRenderer}
        />
      </div>
    </div>
  );
}
