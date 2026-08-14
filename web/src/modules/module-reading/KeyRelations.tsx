import {
  isRelationType,
  type RelationType,
  type RendererInput,
} from "./model";

export interface KeyRelationsProps {
  readonly input: RendererInput;
}

const relationVerbByType = {
  DEPENDS_ON: "依赖于",
  EXPLAINS: "解释",
  CONTRASTS_WITH: "对照于",
  APPLIES_TO: "适用于",
  IMPACTS: "影响",
} satisfies Readonly<Record<RelationType, string>>;

export function KeyRelations({ input }: KeyRelationsProps) {
  if (input.relations.length === 0) {
    throw new Error("MODULE_DEFAULT_READING_RELATION_REQUIRED");
  }
  if (input.relations.length > 3) {
    throw new Error("MODULE_DEFAULT_READING_RELATION_BUDGET_EXCEEDED");
  }

  const nodeById = new Map(input.nodes.map((node) => [node.nodeId, node]));
  const resolvedRelations = input.relations.map((relation) => {
    if (!isRelationType(relation.type)) {
      throw new Error("RENDERER_RELATION_TYPE_UNSUPPORTED");
    }
    const sourceNode = nodeById.get(relation.sourceNodeRef);
    const targetNode = nodeById.get(relation.targetNodeRef);
    if (sourceNode === undefined || targetNode === undefined) {
      throw new Error("RENDERER_RELATION_ENDPOINT_MISSING");
    }
    return { relation, sourceNode, targetNode };
  });

  return (
    <section
      aria-labelledby="key-relations-heading"
      className="key-relations"
      data-reading-section="relations"
    >
      <h2 className="cka-type-major-section" id="key-relations-heading">
        局部关系
      </h2>
      <ul aria-label="局部关系">
        {resolvedRelations.map(({ relation, sourceNode, targetNode }) => (
          <li
            className="cka-relation-statement"
            data-relation-id={relation.relationId}
            data-relation-type={relation.type}
            data-source-node-ref={relation.sourceNodeRef}
            data-target-node-ref={relation.targetNodeRef}
            key={relation.relationId}
          >
            <span
              className="cka-relation-endpoint"
              data-relation-part="source"
            >
              {sourceNode.label}
            </span>
            <span className="cka-relation-verb" data-relation-part="type">
              {relationVerbByType[relation.type]}
            </span>
            <span
              aria-hidden="true"
              className="cka-relation-direction"
              data-relation-part="direction"
            />
            <span
              className="cka-relation-endpoint"
              data-relation-part="target"
            >
              {targetNode.label}
            </span>
          </li>
        ))}
      </ul>
    </section>
  );
}
