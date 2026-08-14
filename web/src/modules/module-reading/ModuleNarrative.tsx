import type { ModuleNarrativeProjection } from "./model";

export interface ModuleNarrativeProps {
  readonly projection: ModuleNarrativeProjection;
}

export function ModuleNarrative({ projection }: ModuleNarrativeProps) {
  return (
    <>
      <section
        aria-labelledby="module-narrative-questions-heading"
        className="module-narrative__questions"
        data-reading-section="core-questions"
      >
        <h2
          className="cka-type-major-section"
          id="module-narrative-questions-heading"
        >
          核心问题
        </h2>
        <ul aria-label="核心问题">
          {projection.coreQuestions.map((question, index) => (
            <li key={`${projection.moduleRef}:question:${index}`}>{question}</li>
          ))}
        </ul>
      </section>

      <section
        aria-labelledby="module-narrative-conclusion-heading"
        className="module-narrative__conclusion"
        data-reading-section="core-conclusion"
      >
        <h2
          className="cka-type-major-section"
          id="module-narrative-conclusion-heading"
        >
          核心结论
        </h2>
        <p className="cka-type-reading">{projection.coreConclusion}</p>
      </section>

      <section
        aria-labelledby="module-narrative-spine-heading"
        className="module-narrative__spine"
        data-reading-section="primary-spine"
      >
        <h2
          className="cka-type-major-section"
          id="module-narrative-spine-heading"
        >
          认知主线
        </h2>
        <ol aria-label="认知主线">
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
