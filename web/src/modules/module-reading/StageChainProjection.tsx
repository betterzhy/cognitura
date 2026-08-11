import type { RendererInput } from "./model";

export interface StageChainProjectionProps {
  readonly moduleRef: string;
  readonly input: RendererInput;
}

export function StageChainProjection({
  moduleRef,
  input,
}: StageChainProjectionProps) {
  if (input.rendererType !== "STAGE_CHAIN") {
    throw new Error("RENDERER_TYPE_MISMATCH");
  }
  if (input.moduleRef !== moduleRef) {
    throw new Error("RENDERER_MODULE_REF_MISMATCH");
  }

  return (
    <section data-reading-section="stage-chain">
      <ol aria-label="Stage chain">
        {input.nodes.map((node) => (
          <li data-node-id={node.nodeId} key={node.nodeId}>
            <strong>{node.label}</strong>
            <span>{node.summary}</span>
          </li>
        ))}
      </ol>
    </section>
  );
}
