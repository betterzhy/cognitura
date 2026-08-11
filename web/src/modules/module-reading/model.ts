export type SchemaVersion = "2.0.0";

export type PublicationState = "DRAFT" | "CONFIRMED" | "PUBLISHED";

export type KnowledgeRole =
  | "FOUNDATION"
  | "CORE"
  | "BRIDGE"
  | "APPLICATION"
  | "EXTENSION";

export interface PrimaryCognitiveSpineStep {
  readonly stepId: string;
  readonly order: number;
  readonly statement: string;
  readonly sourceRefs: readonly string[];
}

export interface PrimaryCognitiveSpine {
  readonly schemaVersion: SchemaVersion;
  readonly artifactId: string;
  readonly revisionId: string;
  readonly publicationState: PublicationState;
  readonly moduleRef: string;
  readonly steps: readonly PrimaryCognitiveSpineStep[];
}

type CanonicalObject = Readonly<Record<string, unknown>>;

export interface CognitiveModule {
  readonly schemaVersion: SchemaVersion;
  readonly artifactId: string;
  readonly revisionId: string;
  readonly publicationState: PublicationState;
  readonly primaryParent: string;
  readonly title: string;
  readonly thesis: string;
  readonly role: KnowledgeRole;
  readonly coreQuestions: readonly string[];
  readonly primaryCognitiveSpine: PrimaryCognitiveSpine | null;
  readonly facets: readonly CanonicalObject[];
  readonly knowledgeElements: readonly CanonicalObject[];
  readonly keyTakeaways: readonly CanonicalObject[];
  readonly criticalBoundaries: readonly CanonicalObject[];
  readonly relations: readonly CanonicalObject[];
  readonly sourceRefs: readonly string[];
  readonly gaps: readonly CanonicalObject[];
  readonly qualityAssessment: CanonicalObject | null;
}

export interface ModuleNarrativeProjection {
  readonly moduleRef: string;
  readonly title: string;
  readonly coreQuestions: readonly string[];
  readonly coreConclusion: string;
  readonly spineSteps: readonly PrimaryCognitiveSpineStep[];
}
