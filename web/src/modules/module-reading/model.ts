export type SchemaVersion = "2.0.0";

export type PublicationState = "DRAFT" | "CONFIRMED" | "PUBLISHED";

export type KnowledgeRole =
  | "FOUNDATION"
  | "CORE"
  | "BRIDGE"
  | "APPLICATION"
  | "EXTENSION";

export type KnowledgeElementType =
  | "CONCEPT"
  | "RULE"
  | "MECHANISM"
  | "STEP"
  | "DISTINCTION"
  | "BOUNDARY"
  | "EXAMPLE"
  | "PRACTICE";

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

export interface KnowledgeElement {
  readonly schemaVersion: SchemaVersion;
  readonly artifactId: string;
  readonly revisionId: string;
  readonly publicationState: PublicationState;
  readonly moduleRef: string;
  readonly elementType: KnowledgeElementType;
  readonly title: string;
  readonly content: string;
  readonly sourceRefs: readonly string[];
  readonly relations: readonly string[];
}

export interface CriticalBoundary {
  readonly boundaryId: string;
  readonly statement: string;
  readonly sourceRefs: readonly string[];
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
  readonly knowledgeElements: readonly KnowledgeElement[];
  readonly keyTakeaways: readonly CanonicalObject[];
  readonly criticalBoundaries: readonly CriticalBoundary[];
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

export interface ModuleClosureProjection {
  readonly knowledgeElements: readonly KnowledgeElement[];
  readonly criticalBoundaries: readonly CriticalBoundary[];
}
