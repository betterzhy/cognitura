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
    <section
      aria-labelledby="stage-chain-projection-heading"
      className="stage-chain-projection"
      data-reading-section="stage-chain"
    >
      <header className="stage-chain-projection__header">
        <p className="stage-chain-projection__label">机制路径</p>
        <h2
          className="cka-type-major-section"
          id="stage-chain-projection-heading"
        >
          {input.title}
        </h2>
        <p className="stage-chain-projection__summary">{input.summary}</p>
      </header>
      <ol aria-label="机制路径">
        {input.nodes.map((node, index) => (
          <li data-node-id={node.nodeId} key={node.nodeId}>
            <span
              aria-hidden="true"
              className="stage-chain-projection__number"
            >
              {index + 1}
            </span>
            <span className="stage-chain-projection__content">
              <strong>{node.label}</strong>
              <span>{node.summary}</span>
            </span>
          </li>
        ))}
      </ol>
    </section>
  );
}
