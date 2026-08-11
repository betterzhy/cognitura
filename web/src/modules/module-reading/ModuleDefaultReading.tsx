/// <reference types="vite/client" />

import { KeyRelations } from "./KeyRelations";
import { ModuleClosure } from "./ModuleClosure";
import { ModuleNarrative } from "./ModuleNarrative";
import type { CognitiveModule, RendererInput } from "./model";
import { projectModuleClosure, projectModuleNarrative } from "./projectModuleNarrative";
import { SourceEntry } from "./SourceEntry";
import { StageChainProjection } from "./StageChainProjection";

import "./module-default-reading.css";

export interface ModuleDefaultReadingProps {
  readonly module: CognitiveModule;
  readonly rendererInput: RendererInput;
}

export function ModuleDefaultReading({
  module,
  rendererInput,
}: ModuleDefaultReadingProps) {
  const narrative = projectModuleNarrative(module);
  const closure = projectModuleClosure(module);

  return (
    <main aria-label={module.title} className="module-default-reading">
      <h1>{module.title}</h1>
      <ModuleNarrative projection={narrative} />
      <div data-primary-visual-projection="true">
        <StageChainProjection moduleRef={module.artifactId} input={rendererInput} />
      </div>
      <ModuleClosure
        boundaries={closure.criticalBoundaries}
        elements={closure.knowledgeElements}
      />
      <KeyRelations input={rendererInput} />
      <SourceEntry sourceRefs={rendererInput.sourceRefs} />
    </main>
  );
}
