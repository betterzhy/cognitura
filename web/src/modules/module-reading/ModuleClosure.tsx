import type { CriticalBoundary, KnowledgeElement } from "./model";

export interface ModuleClosureProps {
  readonly boundaries: readonly CriticalBoundary[];
  readonly elements: readonly KnowledgeElement[];
}

export function ModuleClosure({ boundaries, elements }: ModuleClosureProps) {
  return (
    <>
      <section
        aria-labelledby="module-closure-boundaries-heading"
        className="module-closure__boundaries cka-semantic-boundary"
        data-reading-section="boundaries"
      >
        <h2
          className="cka-type-major-section"
          id="module-closure-boundaries-heading"
        >
          边界与例外
        </h2>
        <ul aria-label="边界与例外">
          {boundaries.map((boundary) => (
            <li
              data-boundary-id={boundary.boundaryId}
              key={boundary.boundaryId}
            >
              {boundary.statement}
            </li>
          ))}
        </ul>
      </section>

      <section
        aria-labelledby="module-closure-elements-heading"
        className="module-closure__elements"
        data-reading-section="elements"
      >
        <h2
          className="cka-type-major-section"
          id="module-closure-elements-heading"
        >
          关键知识
        </h2>
        <ul aria-label="关键知识">
          {elements.map((element) => (
            <li data-element-id={element.artifactId} key={element.artifactId}>
              <strong>{element.title}</strong>
              <span>{element.content}</span>
            </li>
          ))}
        </ul>
      </section>
    </>
  );
}
