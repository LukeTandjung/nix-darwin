import { randomUUID } from 'node:crypto';

import type { Type } from '@oh-my-pi/omptype';
import type { ExtensionAPI } from '@oh-my-pi/pi-coding-agent';

import type { Schema } from './schema';

const MAX_HISTORY_COUNT = 500;

export function createStateSchemas(
  type: ExtensionAPI['arktype'],
): StateSchemas {
  const probeStrand = type({
    name: 'string > 0',
    floor: 'string > 0',
    ceiling: 'string > 0',
    misconceptions: 'string',
    buildFrom: 'string > 0',
  });
  const planNode = type({
    id: 'string > 0',
    title: 'string > 0',
    dependsOn: 'string[]',
  });
  const activeCheck = type({
    nodeId: 'string > 0',
    question: 'string > 0',
    committedAnswer: 'string > 0',
    createdAt: 'string > 0',
  });
  const checkRecord = type({
    nodeId: 'string > 0',
    verdict: "'held' | 'fragile' | 'gap'",
    diagnosis: 'string > 0',
    createdAt: 'string > 0',
  });
  const learning = type({
    version: '1',
    id: 'string > 0',
    kind: "'learn'",
    goal: 'string > 0',
    phase: "'probe' | 'plan' | 'teach' | 'complete'",
    strands: probeStrand.array(),
    plan: planNode.array().or('null'),
    activeCheck: activeCheck.or('null'),
    checks: checkRecord.array().atMostLength(MAX_HISTORY_COUNT),
    createdAt: 'string > 0',
    updatedAt: 'string > 0',
  });
  const activeProblem = type({
    statement: 'string > 0',
    solution: 'string > 0',
    targetNodeIds: 'string[]',
    createdAt: 'string > 0',
  });
  const practiceOutcome = type({
    statement: 'string > 0',
    solution: 'string > 0',
    targetNodeIds: 'string[]',
    outcome: "'correct' | 'partial' | 'incorrect' | 'dismissed'",
    diagnosis: 'string > 0',
    createdAt: 'string > 0',
  });
  const practice = type({
    version: '1',
    id: 'string > 0',
    kind: "'practice'",
    topic: 'string > 0',
    activeProblem: activeProblem.or('null'),
    outcomes: practiceOutcome.array().atMostLength(MAX_HISTORY_COUNT),
    createdAt: 'string > 0',
    updatedAt: 'string > 0',
  });
  return {
    session: learning.or(practice),
    probeStrands: probeStrand.array().atLeastLength(1).atMostLength(20),
    planNodes: planNode.array().atLeastLength(1).atMostLength(40),
  };
}

export interface ProbeStrand {
  name: string;
  floor: string;
  ceiling: string;
  misconceptions: string;
  buildFrom: string;
}

export interface PlanNode {
  id: string;
  title: string;
  dependsOn: Array<string>;
}

export interface ActiveCheck {
  nodeId: string;
  question: string;
  committedAnswer: string;
  createdAt: string;
}

export type CheckVerdict = 'held' | 'fragile' | 'gap';

export interface CheckRecord {
  nodeId: string;
  verdict: CheckVerdict;
  diagnosis: string;
  createdAt: string;
}

export interface LearningState {
  version: 1;
  id: string;
  kind: 'learn';
  goal: string;
  phase: 'probe' | 'plan' | 'teach' | 'complete';
  strands: Array<ProbeStrand>;
  plan: Array<PlanNode> | null;
  activeCheck: ActiveCheck | null;
  checks: Array<CheckRecord>;
  createdAt: string;
  updatedAt: string;
}

export interface ActiveProblem {
  statement: string;
  solution: string;
  targetNodeIds: Array<string>;
  createdAt: string;
}

export type PracticeOutcome = 'correct' | 'partial' | 'incorrect' | 'dismissed';

export interface PracticeOutcomeRecord extends ActiveProblem {
  outcome: PracticeOutcome;
  diagnosis: string;
}

export interface PracticeState {
  version: 1;
  id: string;
  kind: 'practice';
  topic: string;
  activeProblem: ActiveProblem | null;
  outcomes: Array<PracticeOutcomeRecord>;
  createdAt: string;
  updatedAt: string;
}

export type LearningSessionState = LearningState | PracticeState;

export interface StateSchemas {
  session: Schema<LearningSessionState>;
  probeStrands: Type<Array<ProbeStrand>>;
  planNodes: Type<Array<PlanNode>>;
}

export function createLearningState(goal: string, now: string): LearningState {
  return {
    version: 1,
    id: randomUUID(),
    kind: 'learn',
    goal: requiredText(goal, 'goal'),
    phase: 'probe',
    strands: [],
    plan: null,
    activeCheck: null,
    checks: [],
    createdAt: now,
    updatedAt: now,
  };
}

export function createPracticeState(topic: string, now: string): PracticeState {
  return {
    version: 1,
    id: randomUUID(),
    kind: 'practice',
    topic: requiredText(topic, 'topic'),
    activeProblem: null,
    outcomes: [],
    createdAt: now,
    updatedAt: now,
  };
}

export function finishProbe(
  state: LearningState,
  strands: Array<ProbeStrand>,
  now: string,
): LearningState {
  requirePhase(state, 'probe');
  if (strands.length === 0)
    throw new Error('Record at least one probed strand.');
  return { ...state, phase: 'plan', strands, updatedAt: now };
}

export function writePlan(
  state: LearningState,
  nodes: Array<PlanNode>,
  now: string,
): LearningState {
  requirePhase(state, 'plan');
  const validatedNodes = validatePlan(nodes);
  return { ...state, phase: 'teach', plan: validatedNodes, updatedAt: now };
}

export function beginCheck(
  state: LearningState,
  input: { nodeId: string; question: string; committedAnswer: string },
  now: string,
): LearningState {
  requirePhase(state, 'teach');
  if (state.activeCheck !== null)
    throw new Error('Resolve the active check first.');
  if (!state.plan?.some((node) => node.id === input.nodeId)) {
    throw new Error(`Unknown plan node: ${input.nodeId}`);
  }
  const activeCheck = {
    nodeId: input.nodeId,
    question: requiredText(input.question, 'question'),
    committedAnswer: requiredText(input.committedAnswer, 'committedAnswer'),
    createdAt: now,
  };
  return { ...state, activeCheck, updatedAt: now };
}

export function resolveCheck(
  state: LearningState,
  input: { verdict: CheckVerdict; diagnosis: string },
  now: string,
): LearningState {
  requirePhase(state, 'teach');
  if (state.activeCheck === null)
    throw new Error('There is no active check to resolve.');
  if (state.checks.length >= MAX_HISTORY_COUNT) {
    throw new Error(
      'This lesson reached its check-history limit; start a new lesson.',
    );
  }
  const record = {
    nodeId: state.activeCheck.nodeId,
    verdict: input.verdict,
    diagnosis: requiredText(input.diagnosis, 'diagnosis'),
    createdAt: now,
  };
  return {
    ...state,
    activeCheck: null,
    checks: [...state.checks, record],
    updatedAt: now,
  };
}

export function completeLearning(
  state: LearningState,
  now: string,
): LearningState {
  requirePhase(state, 'teach');
  if (state.activeCheck !== null)
    throw new Error('Resolve the active check first.');
  const incomplete = (state.plan ?? []).filter(
    (node) =>
      state.checks.findLast((check) => check.nodeId === node.id)?.verdict !==
      'held',
  );
  if (incomplete.length > 0) {
    throw new Error(
      `Plan nodes are not currently held: ${incomplete.map((node) => node.id).join(', ')}`,
    );
  }
  return { ...state, phase: 'complete', updatedAt: now };
}

export function beginProblem(
  state: PracticeState,
  input: { statement: string; solution: string; targetNodeIds: Array<string> },
  now: string,
): PracticeState {
  if (state.activeProblem !== null)
    throw new Error('Conclude the active problem first.');
  const activeProblem = {
    statement: requiredText(input.statement, 'statement'),
    solution: requiredText(input.solution, 'solution'),
    targetNodeIds: [...new Set(input.targetNodeIds)],
    createdAt: now,
  };
  return { ...state, activeProblem, updatedAt: now };
}

export function concludeProblem(
  state: PracticeState,
  input: { outcome: PracticeOutcome; diagnosis: string },
  now: string,
): PracticeState {
  if (state.activeProblem === null)
    throw new Error('There is no active problem to conclude.');
  if (state.outcomes.length >= MAX_HISTORY_COUNT) {
    throw new Error(
      'This practice session reached its outcome limit; start a new session.',
    );
  }
  const outcome = {
    ...state.activeProblem,
    outcome: input.outcome,
    diagnosis: requiredText(input.diagnosis, 'diagnosis'),
    createdAt: now,
  };
  return {
    ...state,
    activeProblem: null,
    outcomes: [...state.outcomes, outcome],
    updatedAt: now,
  };
}

export function formatStateForPrompt(state: LearningSessionState): string {
  if (state.kind === 'practice') {
    return JSON.stringify({
      ...state,
      outcomes: state.outcomes.slice(-10),
    });
  }
  return JSON.stringify({
    ...state,
    checks: state.checks.slice(-10),
  });
}

export function formatStatus(state: LearningSessionState): string {
  if (state.kind === 'practice') {
    const active =
      state.activeProblem === null ? 'none' : 'awaiting conclusion';
    return `Practice: ${state.topic}\nActive problem: ${active}\nOutcomes: ${state.outcomes.length}`;
  }
  const held = state.checks.filter((check) => check.verdict === 'held').length;
  return [
    `Learning: ${state.goal}`,
    `Phase: ${state.phase}`,
    `Plan nodes: ${state.plan?.length ?? 0}`,
    `Checks: ${state.checks.length} (${held} held)`,
    `Active check: ${state.activeCheck?.nodeId ?? 'none'}`,
  ].join('\n');
}

function requirePhase(
  state: LearningState,
  phase: LearningState['phase'],
): void {
  if (state.phase !== phase) {
    throw new Error(
      `This operation requires the ${phase} phase; current phase is ${state.phase}.`,
    );
  }
}

function requiredText(value: string, field: string): string {
  const trimmed = value.trim();
  if (trimmed.length === 0) throw new Error(`${field} cannot be blank.`);
  return trimmed;
}

function validatePlan(nodes: Array<PlanNode>): Array<PlanNode> {
  if (nodes.length === 0) throw new Error('The plan needs at least one node.');
  const normalized = nodes.map((node) => ({
    id: requiredText(node.id, 'node id'),
    title: requiredText(node.title, `title for ${node.id}`),
    dependsOn: [...new Set(node.dependsOn)],
  }));
  const ids = new Set(normalized.map((node) => node.id));
  if (ids.size !== normalized.length)
    throw new Error('Plan node IDs must be unique.');
  for (const node of normalized) {
    if (!/^[a-z0-9][a-z0-9-]{0,63}$/.test(node.id)) {
      throw new Error(
        `Invalid node ID: ${node.id}. Use lowercase letters, digits, and hyphens.`,
      );
    }
    for (const dependency of node.dependsOn) {
      if (!ids.has(dependency))
        throw new Error(`Unknown dependency: ${dependency}`);
      if (dependency === node.id)
        throw new Error(`Node ${node.id} depends on itself.`);
    }
  }
  assertAcyclic(normalized);
  return normalized;
}

function assertAcyclic(nodes: Array<PlanNode>): void {
  const dependencies = new Map(nodes.map((node) => [node.id, node.dependsOn]));
  const visiting = new Set<string>();
  const visited = new Set<string>();
  function visit(id: string): void {
    if (visited.has(id)) return;
    if (visiting.has(id))
      throw new Error(`The lesson plan contains a cycle at ${id}.`);
    visiting.add(id);
    for (const dependency of dependencies.get(id) ?? []) visit(dependency);
    visiting.delete(id);
    visited.add(id);
  }
  for (const node of nodes) visit(node.id);
}
