import { isRelationType, type RendererInput } from "./model";

export interface KeyRelationsProps {
  readonly input: RendererInput;
}

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
    <section data-reading-section="relations">
      <ul aria-label="Key relations">
        {resolvedRelations.map(({ relation, sourceNode, targetNode }) => (
          <li
            data-relation-id={relation.relationId}
            data-relation-type={relation.type}
            data-source-node-ref={relation.sourceNodeRef}
            data-target-node-ref={relation.targetNodeRef}
            key={relation.relationId}
          >
            <span data-relation-part="source">{sourceNode.label}</span>
            <span data-relation-part="type">{relation.type}</span>
            <span data-relation-part="target">{targetNode.label}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
