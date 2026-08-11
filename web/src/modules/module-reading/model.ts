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

export interface CognitiveRelation {
  readonly relationId: string;
  readonly type: RelationType;
  readonly sourceRef: string;
  readonly targetRef: string;
  readonly origin: "SOURCE_EXPLICIT" | "SOURCE_SYNTHESIZED";
  readonly riskLevel: "LOW" | "MEDIUM" | "HIGH";
  readonly sourceRefs: readonly string[];
  readonly gapRefs: readonly string[];
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
  readonly relations: readonly CognitiveRelation[];
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

export type RendererType =
  | "HIERARCHY"
  | "MATRIX"
  | "STAGE_CHAIN"
  | "DECISION_PATH"
  | "STATE_TRANSITION"
  | "COMPARISON"
  | "CAUSAL_CHAIN"
  | "LAYERED_STRUCTURE"
  | "STRUCTURED_PANEL";

export const relationTypes = [
  "DEPENDS_ON",
  "EXPLAINS",
  "CONTRASTS_WITH",
  "APPLIES_TO",
  "IMPACTS",
] as const;

export type RelationType = (typeof relationTypes)[number];

export function isRelationType(value: unknown): value is RelationType {
  return relationTypes.includes(value as RelationType);
}

export interface RendererNode {
  readonly nodeId: string;
  readonly artifactRef: string;
  readonly contentPath: string;
  readonly label: string;
  readonly summary: string;
  readonly groupRef: string | null;
  readonly sourceRefs: readonly string[];
}

export interface RendererGroup {
  readonly groupId: string;
  readonly title: string;
  readonly nodeRefs: readonly string[];
  readonly collapsed: boolean;
}

export interface RendererRelation {
  readonly relationId: string;
  readonly type: RelationType;
  readonly sourceNodeRef: string;
  readonly targetNodeRef: string;
  readonly artifactRelationRef: string;
  readonly sourceRefs: readonly string[];
}

export interface RendererIncompleteState {
  readonly status: "COMPLETE" | "PARTIAL" | "BLOCKED_BY_SOURCE_GAP";
  readonly gapRefs: readonly string[];
}

export type RendererInteractionHint =
  | "EXPAND_DETAILS"
  | "SHOW_SOURCE"
  | "FOLD_GROUP";

export interface RendererInput {
  readonly schemaVersion: SchemaVersion;
  readonly moduleRef: string;
  readonly rendererType: RendererType;
  readonly title: string;
  readonly summary: string;
  readonly nodes: readonly RendererNode[];
  readonly groups: readonly RendererGroup[];
  readonly relations: readonly RendererRelation[];
  readonly sourceRefs: readonly string[];
  readonly incompleteState: RendererIncompleteState;
  readonly interactionHints: readonly RendererInteractionHint[];
}
