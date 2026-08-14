import { useId } from "react";

import type { ModuleNarrativeProjection } from "./model";

export interface ModuleNarrativeProps {
  readonly projection: ModuleNarrativeProjection;
}

export function ModuleNarrative({ projection }: ModuleNarrativeProps) {
  const headingBaseId = useId();
  const questionsHeadingId = `${headingBaseId}-questions`;
  const conclusionHeadingId = `${headingBaseId}-conclusion`;
  const spineHeadingId = `${headingBaseId}-spine`;

  return (
    <>
      <section
        aria-labelledby={questionsHeadingId}
        className="module-narrative__questions"
        data-reading-section="core-questions"
      >
        <h2
          className="cka-type-major-section"
          id={questionsHeadingId}
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
        aria-labelledby={conclusionHeadingId}
        className="module-narrative__conclusion"
        data-reading-section="core-conclusion"
      >
        <h2
          className="cka-type-major-section"
          id={conclusionHeadingId}
        >
          核心结论
        </h2>
        <p className="cka-type-reading">{projection.coreConclusion}</p>
      </section>

      <section
        aria-labelledby={spineHeadingId}
        className="module-narrative__spine"
        data-reading-section="primary-spine"
      >
        <h2
          className="cka-type-major-section"
          id={spineHeadingId}
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
