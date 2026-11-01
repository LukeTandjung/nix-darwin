import { describe, expect, it } from 'bun:test';

import {
  beginCheck,
  beginProblem,
  completeLearning,
  concludeProblem,
  createLearningState,
  createPracticeState,
  finishProbe,
  resolveCheck,
  writePlan,
} from './state';

const now = '2026-11-01T00:00:00.000Z';
const strand = {
  name: 'Functions',
  floor: 'Can evaluate a function.',
  ceiling: 'Cannot compose functions.',
  misconceptions: '',
  buildFrom: 'Evaluation and substitution.',
};
const functionNode = { id: 'functions', title: 'Functions', dependsOn: [] };
const plan = [
  functionNode,
  {
    id: 'composition',
    title: 'Function composition',
    dependsOn: ['functions'],
  },
];

describe('learning workflow', () => {
  it('advances through probe, plan, checked teaching, and completion', () => {
    const probed = finishProbe(
      createLearningState('Understand composition', now),
      [strand],
      now,
    );
    const taught = writePlan(probed, plan, now);
    const checking = beginCheck(
      taught,
      {
        nodeId: 'functions',
        question: 'Define a function.',
        committedAnswer: 'A mapping.',
      },
      now,
    );
    const held = resolveCheck(
      checking,
      { verdict: 'held', diagnosis: 'Sound definition.' },
      now,
    );
    const compositionChecking = beginCheck(
      held,
      {
        nodeId: 'composition',
        question: 'Explain composition.',
        committedAnswer: 'Apply one function to another’s output.',
      },
      now,
    );
    const ready = resolveCheck(
      compositionChecking,
      { verdict: 'held', diagnosis: 'Correct reasoning.' },
      now,
    );

    expect(completeLearning(ready, now).phase).toBe('complete');
  });

  it('rejects a cyclic dependency plan', () => {
    const probed = finishProbe(
      createLearningState('Understand cycles', now),
      [strand],
      now,
    );
    const cyclic = [
      { id: 'a', title: 'A', dependsOn: ['b'] },
      { id: 'b', title: 'B', dependsOn: ['a'] },
    ];

    expect(() => writePlan(probed, cyclic, now)).toThrow('cycle');
  });

  it('does not complete when the latest check on a node is a gap', () => {
    const probed = finishProbe(
      createLearningState('Understand functions', now),
      [strand],
      now,
    );
    const oneNodePlan = writePlan(probed, [functionNode], now);
    const first = beginCheck(
      oneNodePlan,
      {
        nodeId: 'functions',
        question: 'Define it.',
        committedAnswer: 'A mapping.',
      },
      now,
    );
    const held = resolveCheck(
      first,
      { verdict: 'held', diagnosis: 'Held.' },
      now,
    );
    const second = beginCheck(
      held,
      {
        nodeId: 'functions',
        question: 'Apply it.',
        committedAnswer: 'Substitute.',
      },
      now,
    );
    const gap = resolveCheck(
      second,
      { verdict: 'gap', diagnosis: 'Cannot apply it.' },
      now,
    );

    expect(() => completeLearning(gap, now)).toThrow('functions');
  });

  it('requires resolving the active check before starting another', () => {
    const probed = finishProbe(
      createLearningState('Understand functions', now),
      [strand],
      now,
    );
    const taught = writePlan(probed, [functionNode], now);
    const checking = beginCheck(
      taught,
      {
        nodeId: 'functions',
        question: 'Define it.',
        committedAnswer: 'A mapping.',
      },
      now,
    );

    expect(() =>
      beginCheck(
        checking,
        {
          nodeId: 'functions',
          question: 'Again.',
          committedAnswer: 'Still a mapping.',
        },
        now,
      ),
    ).toThrow('Resolve the active check');
  });
});

describe('practice workflow', () => {
  it('keeps the committed solution with the recorded outcome', () => {
    const practice = createPracticeState('Function composition', now);
    const active = beginProblem(
      practice,
      {
        statement: 'Compose f and g.',
        solution: 'Apply g, then f.',
        targetNodeIds: ['n_functions'],
      },
      now,
    );
    const concluded = concludeProblem(
      active,
      { outcome: 'partial', diagnosis: 'Reversed the application order.' },
      now,
    );

    expect(concluded.activeProblem).toBeNull();
    expect(concluded.outcomes[0]?.solution).toBe('Apply g, then f.');
    expect(concluded.outcomes[0]?.outcome).toBe('partial');
  });
});
