import { RalphState } from './types.js';
import { readFileOrNull, writeFileSafe, deleteFile, ensureDir } from './utils.js';

const MAX_TODO_CONTINUATION_ATTEMPTS = 5;

export function readRalphState(projectRoot: string, sessionId: string): RalphState | null {
  const path = `${projectRoot}/.omt/ralph-state-${sessionId}.json`;
  const content = readFileOrNull(path);
  if (!content) return null;

  try {
    const state = JSON.parse(content) as RalphState;
    return state.active ? state : null;
  } catch {
    return null;
  }
}

export function updateRalphState(projectRoot: string, sessionId: string, state: RalphState): void {
  const path = `${projectRoot}/.omt/ralph-state-${sessionId}.json`;
  writeFileSafe(path, JSON.stringify(state, null, 2));
}

export function cleanupRalphState(projectRoot: string, sessionId: string): void {
  deleteFile(`${projectRoot}/.omt/ralph-state-${sessionId}.json`);
}

// Attempt counting for stuck agent escape hatch
export function getAttemptCount(stateDir: string, attemptId: string): number {
  const content = readFileOrNull(`${stateDir}/todo-attempts-${attemptId}`);
  return content ? parseInt(content, 10) || 0 : 0;
}

export function incrementAttempts(stateDir: string, attemptId: string): void {
  const current = getAttemptCount(stateDir, attemptId);
  ensureDir(stateDir);
  writeFileSafe(`${stateDir}/todo-attempts-${attemptId}`, String(current + 1));
}

export function resetAttempts(stateDir: string, attemptId: string): void {
  deleteFile(`${stateDir}/todo-attempts-${attemptId}`);
}

export function getTodoCount(stateDir: string, attemptId: string): number {
  const content = readFileOrNull(`${stateDir}/todo-count-${attemptId}`);
  return content ? parseInt(content, 10) : -1;
}

export function saveTodoCount(stateDir: string, attemptId: string, count: number): void {
  ensureDir(stateDir);
  writeFileSafe(`${stateDir}/todo-count-${attemptId}`, String(count));
}

export function cleanupAttemptFiles(stateDir: string, attemptId: string): void {
  deleteFile(`${stateDir}/todo-attempts-${attemptId}`);
  deleteFile(`${stateDir}/todo-count-${attemptId}`);
}

export { MAX_TODO_CONTINUATION_ATTEMPTS };
