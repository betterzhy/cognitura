import type { CriticalBoundary, KnowledgeElement } from "./model";

export interface ModuleClosureProps {
  readonly boundaries: readonly CriticalBoundary[];
  readonly elements: readonly KnowledgeElement[];
}

export function ModuleClosure({ boundaries, elements }: ModuleClosureProps) {
  return (
    <>
      <section data-reading-section="boundaries">
        <h2>Critical boundaries</h2>
        <ul aria-label="Critical boundaries">
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

      <section data-reading-section="elements">
        <h2>Knowledge elements</h2>
        <ul aria-label="Knowledge elements">
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
