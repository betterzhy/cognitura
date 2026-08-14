/// <reference types="vite/client" />

import { useId } from "react";

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

function projectedEntityRef(
  module: CognitiveModule,
  contentPath: string,
): string | undefined {
  if (
    contentPath === "/title" ||
    contentPath === "/thesis" ||
    contentPath === "/role"
  ) {
    return module.artifactId;
  }
  const arrayIndex = "(0|[1-9]\\d*)";
  const coreQuestionMatch = new RegExp(`^/coreQuestions/${arrayIndex}$`).exec(
    contentPath,
  );
  if (coreQuestionMatch !== null) {
    return module.coreQuestions[Number(coreQuestionMatch[1])] === undefined
      ? undefined
      : module.artifactId;
  }

  const indexedEntityPatterns: readonly [
    RegExp,
    (index: number) => unknown,
  ][] = [
    [
      new RegExp(`^/primaryCognitiveSpine/steps/${arrayIndex}/statement$`),
      (index) => module.primaryCognitiveSpine?.steps[index]?.stepId,
    ],
    [
      new RegExp(`^/facets/${arrayIndex}/(?:title|summary)$`),
      (index) => module.facets[index]?.facetId,
    ],
    [
      new RegExp(`^/knowledgeElements/${arrayIndex}/(?:title|content)$`),
      (index) => module.knowledgeElements[index]?.artifactId,
    ],
    [
      new RegExp(`^/keyTakeaways/${arrayIndex}/statement$`),
      (index) => module.keyTakeaways[index]?.statementId,
    ],
    [
      new RegExp(`^/criticalBoundaries/${arrayIndex}/statement$`),
      (index) => module.criticalBoundaries[index]?.boundaryId,
    ],
  ];

  for (const [pattern, entityAt] of indexedEntityPatterns) {
    const match = pattern.exec(contentPath);
    if (match !== null) {
      const entityRef = entityAt(Number(match[1]));
      return typeof entityRef === "string" ? entityRef : undefined;
    }
  }

  return undefined;
}

function hasSameRefs(left: readonly string[], right: readonly string[]) {
  return (
    left.length === right.length &&
    left.every((sourceRef) => right.includes(sourceRef))
  );
}

function validateFormalRelations(
  module: CognitiveModule,
  rendererInput: RendererInput,
) {
  const nodeById = new Map(
    rendererInput.nodes.map((node) => [node.nodeId, node]),
  );
  const formalRelationById = new Map(
    module.relations.map((relation) => [relation.relationId, relation]),
  );

  rendererInput.relations.forEach((relation) => {
    const formalRelation = formalRelationById.get(
      relation.artifactRelationRef,
    );
    if (formalRelation === undefined) {
      throw new Error("RENDERER_RELATION_OUT_OF_SCOPE");
    }
    if (relation.type !== formalRelation.type) {
      throw new Error("RENDERER_RELATION_TYPE_CHANGED");
    }

    const sourceNode = nodeById.get(relation.sourceNodeRef);
    const targetNode = nodeById.get(relation.targetNodeRef);
    if (
      sourceNode === undefined ||
      targetNode === undefined ||
      relation.sourceNodeRef === relation.targetNodeRef ||
      projectedEntityRef(module, sourceNode.contentPath) !==
        formalRelation.sourceRef ||
      projectedEntityRef(module, targetNode.contentPath) !==
        formalRelation.targetRef
    ) {
      throw new Error("RENDERER_RELATION_ENDPOINT_CHANGED");
    }
    if (!hasSameRefs(relation.sourceRefs, formalRelation.sourceRefs)) {
      throw new Error("RENDERER_RELATION_SOURCE_CHANGED");
    }
  });
}

export function ModuleDefaultReading({
  module,
  rendererInput,
}: ModuleDefaultReadingProps) {
  const headingId = `${useId()}-module-heading`;
  const narrative = projectModuleNarrative(module);
  const closure = projectModuleClosure(module);
  validateFormalRelations(module, rendererInput);

  return (
    <main
      aria-labelledby={headingId}
      className="module-default-reading cka-visual-root cka-reading-surface"
      data-reading-flow="continuous-document"
    >
      <header className="module-default-reading__identity">
        <p className="module-default-reading__eyebrow">认知模块</p>
        <h1 className="cka-type-object-title" id={headingId}>
          {module.title}
        </h1>
      </header>
      <ModuleNarrative projection={narrative} />
      <div
        className="module-default-reading__primary-projection cka-projection-surface"
        data-primary-visual-projection="true"
      >
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
