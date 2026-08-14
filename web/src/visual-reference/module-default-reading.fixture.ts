import type {
  CognitiveModule,
  RendererInput,
} from "../modules/module-reading/model";

const sourceRef = "evidence.visual-reference.mvcc";
const moduleRef = "module.mvcc.visual-reference";
const relationRef = "relation.mvcc.visible-result.depends-read-view";
const rendererNodeIds = [
  "renderer-node.mvcc.read-view",
  "renderer-node.mvcc.record-version",
  "renderer-node.mvcc.visibility",
  "renderer-node.mvcc.visible-result",
] as const;

function buildVisualReferenceNodes(
  knowledgeElements: CognitiveModule["knowledgeElements"],
): RendererInput["nodes"] {
  if (knowledgeElements.length !== rendererNodeIds.length) {
    throw new Error("VISUAL_REFERENCE_ELEMENT_COUNT_MISMATCH");
  }
  return rendererNodeIds.map((nodeId, index) => {
    const element = knowledgeElements[index];
    if (element === undefined) {
      throw new Error("VISUAL_REFERENCE_ELEMENT_MISSING");
    }
    return {
      nodeId,
      artifactRef: moduleRef,
      contentPath: `/knowledgeElements/${index}/title`,
      label: element.title,
      summary: element.content,
      groupRef: null,
      sourceRefs: [sourceRef],
    };
  });
}

export const visualReferenceModule: CognitiveModule = {
  schemaVersion: "2.0.0",
  artifactId: moduleRef,
  revisionId: "rev.module.mvcc.visual-reference.1",
  publicationState: "PUBLISHED",
  primaryParent: "theme.database-concurrency",
  title: "MVCC 一致性读",
  thesis:
    "一致性读先固定可见性边界，再沿版本链排除不可见版本，最终返回边界内最新的可见记录。",
  role: "CORE",
  coreQuestions: [
    "一次一致性读，如何从多个记录版本中选出当前事务真正可见的版本？",
  ],
  primaryCognitiveSpine: {
    schemaVersion: "2.0.0",
    artifactId: "spine.mvcc.visual-reference",
    revisionId: "rev.spine.mvcc.visual-reference.1",
    publicationState: "PUBLISHED",
    moduleRef,
    steps: [
      {
        stepId: "spine-step.mvcc.visual-reference.1",
        order: 1,
        statement: "创建读取视图，固定当前事务的可见性边界。",
        sourceRefs: [sourceRef],
      },
      {
        stepId: "spine-step.mvcc.visual-reference.2",
        order: 2,
        statement: "从当前记录定位版本链入口。",
        sourceRefs: [sourceRef],
      },
      {
        stepId: "spine-step.mvcc.visual-reference.3",
        order: 3,
        statement: "比较事务标识与读取视图，排除不可见版本。",
        sourceRefs: [sourceRef],
      },
      {
        stepId: "spine-step.mvcc.visual-reference.4",
        order: 4,
        statement: "返回边界内最新的可见记录。",
        sourceRefs: [sourceRef],
      },
    ],
  },
  facets: [],
  knowledgeElements: [
    {
      schemaVersion: "2.0.0",
      artifactId: "element.mvcc.read-view",
      revisionId: "rev.element.mvcc.read-view.1",
      publicationState: "PUBLISHED",
      moduleRef,
      elementType: "CONCEPT",
      title: "读取视图",
      content: "固定一次一致性读所使用的事务可见性边界。",
      sourceRefs: [sourceRef],
      relations: [relationRef],
    },
    {
      schemaVersion: "2.0.0",
      artifactId: "element.mvcc.record-version",
      revisionId: "rev.element.mvcc.record-version.1",
      publicationState: "PUBLISHED",
      moduleRef,
      elementType: "CONCEPT",
      title: "记录版本",
      content: "保存记录在某次事务修改后的历史状态与版本链指针。",
      sourceRefs: [sourceRef],
      relations: [],
    },
    {
      schemaVersion: "2.0.0",
      artifactId: "element.mvcc.visibility",
      revisionId: "rev.element.mvcc.visibility.1",
      publicationState: "PUBLISHED",
      moduleRef,
      elementType: "MECHANISM",
      title: "可见性判断",
      content: "按读取视图逐项判断创建事务和删除事务是否可见。",
      sourceRefs: [sourceRef],
      relations: [],
    },
    {
      schemaVersion: "2.0.0",
      artifactId: "element.mvcc.visible-result",
      revisionId: "rev.element.mvcc.visible-result.1",
      publicationState: "PUBLISHED",
      moduleRef,
      elementType: "CONCEPT",
      title: "可见结果",
      content: "在版本链中选择满足边界的最新记录版本。",
      sourceRefs: [sourceRef],
      relations: [relationRef],
    },
  ],
  keyTakeaways: [],
  criticalBoundaries: [
    {
      boundaryId: "boundary.mvcc.visual-reference.1",
      statement: "可见性判断解决读版本选择，但不会消除所有写冲突。",
      sourceRefs: [sourceRef],
    },
  ],
  relations: [
    {
      relationId: relationRef,
      type: "DEPENDS_ON",
      sourceRef: "element.mvcc.visible-result",
      targetRef: "element.mvcc.read-view",
      origin: "SOURCE_SYNTHESIZED",
      riskLevel: "LOW",
      sourceRefs: [sourceRef],
      gapRefs: [],
    },
  ],
  sourceRefs: [sourceRef],
  gaps: [],
  qualityAssessment: null,
};

export const visualReferenceRenderer: RendererInput = {
  schemaVersion: "2.0.0",
  moduleRef,
  rendererType: "STAGE_CHAIN",
  title: "一致性读的可见版本选择机制",
  summary: "从读取视图到可见结果的四步认知路径。",
  nodes: buildVisualReferenceNodes(visualReferenceModule.knowledgeElements),
  groups: [],
  relations: [
    {
      relationId: "renderer-relation.mvcc.visible-result.depends-read-view",
      type: "DEPENDS_ON",
      sourceNodeRef: "renderer-node.mvcc.visible-result",
      targetNodeRef: "renderer-node.mvcc.read-view",
      artifactRelationRef: relationRef,
      sourceRefs: [sourceRef],
    },
  ],
  sourceRefs: [sourceRef],
  incompleteState: { status: "COMPLETE", gapRefs: [] },
  interactionHints: ["SHOW_SOURCE"],
};
