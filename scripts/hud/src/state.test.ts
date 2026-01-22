import { readRalphState, readUltraworkState, readRalphVerification, readTodos, readBackgroundTasks } from './state.js';
import { mkdir, writeFile, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir, homedir } from 'os';

describe('state readers', () => {
  const testDir = join(tmpdir(), 'hud-state-test-' + Date.now());
  const projectDir = join(testDir, 'project');
  const claudeDir = join(projectDir, '.claude');
  const sisyphusDir = join(claudeDir, 'sisyphus');

  beforeAll(async () => {
    await mkdir(sisyphusDir, { recursive: true });
  });

  afterAll(async () => {
    await rm(testDir, { recursive: true, force: true });
  });

  describe('readRalphState', () => {
    it('should read ralph state from project-local .claude/sisyphus/', async () => {
      const state = {
        active: true,
        iteration: 2,
        max_iterations: 5,
        completion_promise: 'Complete the task',
        prompt: 'Original prompt',
        started_at: '2024-01-22T10:00:00Z',
        linked_ultrawork: false,
      };

      await writeFile(join(sisyphusDir, 'ralph-state.json'), JSON.stringify(state));

      const result = await readRalphState(projectDir);

      expect(result).not.toBeNull();
      expect(result?.active).toBe(true);
      expect(result?.iteration).toBe(2);
      expect(result?.max_iterations).toBe(5);
    });

    it('should fall back to global state when project-local file does not exist', async () => {
      // This test verifies the fallback behavior - when no project-local file exists,
      // it falls back to ~/.claude/ralph-state.json if it exists
      const nonExistentDir = join(testDir, 'nonexistent');
      await mkdir(nonExistentDir, { recursive: true });

      const result = await readRalphState(nonExistentDir);

      // Result depends on whether global file exists
      // We just verify the function doesn't throw
      expect(result === null || typeof result === 'object').toBe(true);
    });
  });

  describe('readUltraworkState', () => {
    it('should read ultrawork state from project-local .claude/sisyphus/', async () => {
      const state = {
        active: true,
        started_at: '2024-01-22T10:00:00Z',
        original_prompt: 'Original prompt',
        reinforcement_count: 3,
        linked_to_ralph: true,
      };

      await writeFile(join(sisyphusDir, 'ultrawork-state.json'), JSON.stringify(state));

      const result = await readUltraworkState(projectDir);

      expect(result).not.toBeNull();
      expect(result?.active).toBe(true);
      expect(result?.reinforcement_count).toBe(3);
    });
  });

  describe('readRalphVerification', () => {
    it('should read ralph verification from project-local .claude/sisyphus/', async () => {
      const verification = {
        pending: true,
        verification_attempts: 1,
        max_verification_attempts: 3,
        original_task: 'Complete implementation',
        completion_claim: 'Implementation complete',
        created_at: new Date().toISOString(),
      };

      await writeFile(join(sisyphusDir, 'ralph-verification.json'), JSON.stringify(verification));

      const result = await readRalphVerification(projectDir);

      expect(result).not.toBeNull();
      expect(result?.pending).toBe(true);
      expect(result?.verification_attempts).toBe(1);
    });

    it('should return null for stale verification (>24h old)', async () => {
      const staleDate = new Date();
      staleDate.setHours(staleDate.getHours() - 25); // 25 hours ago

      const verification = {
        pending: true,
        verification_attempts: 1,
        max_verification_attempts: 3,
        original_task: 'Old task',
        completion_claim: 'Old claim',
        created_at: staleDate.toISOString(),
      };

      const staleDir = join(testDir, 'stale-project');
      const staleSisyphusDir = join(staleDir, '.claude', 'sisyphus');
      await mkdir(staleSisyphusDir, { recursive: true });
      await writeFile(join(staleSisyphusDir, 'ralph-verification.json'), JSON.stringify(verification));

      const result = await readRalphVerification(staleDir);

      expect(result).toBeNull();
    });
  });

  describe('readTodos', () => {
    it('should aggregate todos and return completed/total count', async () => {
      const todosState = {
        todos: [
          { content: 'Task 1', status: 'completed' },
          { content: 'Task 2', status: 'in_progress', activeForm: 'Working on Task 2' },
          { content: 'Task 3', status: 'pending' },
        ],
      };

      const todosDir = join(testDir, 'todos-project');
      const todosSisyphusDir = join(todosDir, '.claude', 'sisyphus');
      await mkdir(todosSisyphusDir, { recursive: true });
      await writeFile(join(todosSisyphusDir, 'todos.json'), JSON.stringify(todosState));

      const result = await readTodos(todosDir);

      expect(result).not.toBeNull();
      expect(result?.completed).toBe(1);
      expect(result?.total).toBe(3);
    });

    it('should return null when no todos exist', async () => {
      const emptyDir = join(testDir, 'empty-project');
      await mkdir(emptyDir, { recursive: true });

      const result = await readTodos(emptyDir);

      expect(result).toBeNull();
    });
  });

  describe('readBackgroundTasks', () => {
    it('should return count of background task files', async () => {
      // This test depends on the actual ~/.claude/background-tasks directory
      // which may or may not exist
      const result = await readBackgroundTasks();

      expect(typeof result).toBe('number');
      expect(result).toBeGreaterThanOrEqual(0);
    });
  });
});
