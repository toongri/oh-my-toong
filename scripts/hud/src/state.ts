import { readFile, readdir } from 'fs/promises';
import { join } from 'path';
import { homedir } from 'os';
import type { RalphState, UltraworkState, RalphVerification, TodosState, TodoItem } from './types.js';

async function readJsonFile<T>(path: string): Promise<T | null> {
  try {
    const content = await readFile(path, 'utf8');
    return JSON.parse(content) as T;
  } catch {
    return null;
  }
}

async function findStateFile<T>(cwd: string, filename: string): Promise<T | null> {
  // Priority 1: Project-local
  const localPath = join(cwd, '.claude', 'sisyphus', filename);
  const local = await readJsonFile<T>(localPath);
  if (local) return local;

  // Priority 2: Global fallback
  const globalPath = join(homedir(), '.claude', filename);
  return readJsonFile<T>(globalPath);
}

export async function readRalphState(cwd: string): Promise<RalphState | null> {
  return findStateFile<RalphState>(cwd, 'ralph-state.json');
}

export async function readUltraworkState(cwd: string): Promise<UltraworkState | null> {
  return findStateFile<UltraworkState>(cwd, 'ultrawork-state.json');
}

export async function readRalphVerification(cwd: string): Promise<RalphVerification | null> {
  const verification = await findStateFile<RalphVerification>(cwd, 'ralph-verification.json');

  // Check if stale (>24h)
  if (verification?.created_at) {
    const createdAt = new Date(verification.created_at).getTime();
    const now = Date.now();
    const hours24 = 24 * 60 * 60 * 1000;
    if (now - createdAt > hours24) {
      return null; // Treat as inactive
    }
  }

  return verification;
}

export async function readTodos(cwd: string): Promise<{ completed: number; total: number } | null> {
  const allTodos: TodoItem[] = [];

  // Priority 1: Project-local sisyphus todos
  const sisyphusPath = join(cwd, '.claude', 'sisyphus', 'todos.json');
  const sisyphusTodos = await readJsonFile<TodosState>(sisyphusPath);
  if (sisyphusTodos?.todos) {
    allTodos.push(...sisyphusTodos.todos);
  }

  // Priority 2: Project-local claude todos
  const localPath = join(cwd, '.claude', 'todos.json');
  const localTodos = await readJsonFile<TodosState>(localPath);
  if (localTodos?.todos) {
    allTodos.push(...localTodos.todos);
  }

  // Priority 3: Global todos directory
  const globalTodosDir = join(homedir(), '.claude', 'todos');
  try {
    const files = await readdir(globalTodosDir);
    for (const file of files) {
      if (file.endsWith('.json')) {
        const fileTodos = await readJsonFile<TodosState>(join(globalTodosDir, file));
        if (fileTodos?.todos) {
          allTodos.push(...fileTodos.todos);
        }
      }
    }
  } catch {
    // Directory doesn't exist, skip
  }

  if (allTodos.length === 0) return null;

  const completed = allTodos.filter(t => t.status === 'completed').length;
  return { completed, total: allTodos.length };
}

export async function readBackgroundTasks(): Promise<number> {
  const tasksDir = join(homedir(), '.claude', 'background-tasks');
  try {
    const files = await readdir(tasksDir);
    return files.filter(f => f.endsWith('.json')).length;
  } catch {
    return 0;
  }
}
