import type {
  CognitiveModule,
  ModuleClosureProjection,
  ModuleNarrativeProjection,
} from "./model";

const unpublishedModuleError =
  "MODULE_READING_REQUIRES_PUBLISHED_CANONICAL_MODULE";

export function projectModuleNarrative(
  module: CognitiveModule,
): ModuleNarrativeProjection {
  if (
    module.publicationState !== "PUBLISHED" ||
    module.primaryCognitiveSpine === null
  ) {
    throw new Error(unpublishedModuleError);
  }

  return {
    moduleRef: module.artifactId,
    title: module.title,
    coreQuestions: module.coreQuestions,
    coreConclusion: module.thesis,
    spineSteps: module.primaryCognitiveSpine.steps,
  };
}

export function projectModuleClosure(
  module: Pick<CognitiveModule, "knowledgeElements" | "criticalBoundaries">,
): ModuleClosureProjection {
  return {
    knowledgeElements: module.knowledgeElements,
    criticalBoundaries: module.criticalBoundaries,
  };
}
