import type { ModuleNarrativeProjection } from "./model";

export interface ModuleNarrativeProps {
  readonly projection: ModuleNarrativeProjection;
}

export function ModuleNarrative({ projection }: ModuleNarrativeProps) {
  return (
    <>
      <section data-reading-section="core-questions">
        <h2>Core questions</h2>
        <ul aria-label="Core questions">
          {projection.coreQuestions.map((question, index) => (
            <li key={`${projection.moduleRef}:question:${index}`}>{question}</li>
          ))}
        </ul>
      </section>

      <section
        aria-label="Core conclusion"
        data-reading-section="core-conclusion"
      >
        <h2>Core conclusion</h2>
        <p>{projection.coreConclusion}</p>
      </section>

      <section data-reading-section="primary-spine">
        <h2>Primary cognitive spine</h2>
        <ol aria-label="Primary cognitive spine">
          {projection.spineSteps.map((step) => (
            <li data-step-id={step.stepId} key={step.stepId}>
              {step.statement}
            </li>
          ))}
        </ol>
      </section>
    </>
  );
}
