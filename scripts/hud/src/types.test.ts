import type {
  StdinInput,
  RalphState,
  UltraworkState,
  RalphVerification,
  TodoItem,
  TodosState,
  HudData,
} from './types.js';
import { ANSI } from './types.js';

describe('types', () => {
  describe('StdinInput', () => {
    it('should accept valid stdin input structure', () => {
      const input: StdinInput = {
        hook_event_name: 'test',
        session_id: 'session-123',
        transcript_path: '/path/to/transcript',
        cwd: '/current/working/dir',
        context_window: {
          used_percentage: 50,
          total_input_tokens: 1000,
          context_window_size: 200000,
        },
      };

      expect(input.hook_event_name).toBe('test');
      expect(input.session_id).toBe('session-123');
      expect(input.context_window.used_percentage).toBe(50);
    });

    it('should accept optional workspace field', () => {
      const input: StdinInput = {
        hook_event_name: 'test',
        session_id: 'session-123',
        transcript_path: '/path/to/transcript',
        cwd: '/current/working/dir',
        workspace: { project_dir: '/project/dir' },
        context_window: {
          used_percentage: 50,
          total_input_tokens: 1000,
          context_window_size: 200000,
        },
      };

      expect(input.workspace?.project_dir).toBe('/project/dir');
    });
  });

  describe('RalphState', () => {
    it('should accept valid ralph state structure', () => {
      const state: RalphState = {
        active: true,
        iteration: 2,
        max_iterations: 5,
        completion_promise: 'Complete the task',
        prompt: 'Original prompt',
        started_at: '2024-01-22T10:00:00Z',
        linked_ultrawork: false,
      };

      expect(state.active).toBe(true);
      expect(state.iteration).toBe(2);
      expect(state.max_iterations).toBe(5);
    });
  });

  describe('UltraworkState', () => {
    it('should accept valid ultrawork state structure', () => {
      const state: UltraworkState = {
        active: true,
        started_at: '2024-01-22T10:00:00Z',
        original_prompt: 'Original prompt',
        reinforcement_count: 3,
        linked_to_ralph: true,
      };

      expect(state.active).toBe(true);
      expect(state.reinforcement_count).toBe(3);
    });

    it('should accept optional last_checked_at field', () => {
      const state: UltraworkState = {
        active: true,
        started_at: '2024-01-22T10:00:00Z',
        original_prompt: 'Original prompt',
        reinforcement_count: 3,
        last_checked_at: '2024-01-22T11:00:00Z',
        linked_to_ralph: false,
      };

      expect(state.last_checked_at).toBe('2024-01-22T11:00:00Z');
    });
  });

  describe('RalphVerification', () => {
    it('should accept valid ralph verification structure', () => {
      const verification: RalphVerification = {
        pending: true,
        verification_attempts: 1,
        max_verification_attempts: 3,
        original_task: 'Complete implementation',
        completion_claim: 'Implementation complete',
        created_at: '2024-01-22T10:00:00Z',
      };

      expect(verification.pending).toBe(true);
      expect(verification.verification_attempts).toBe(1);
    });

    it('should accept optional oracle_feedback field', () => {
      const verification: RalphVerification = {
        pending: false,
        verification_attempts: 2,
        max_verification_attempts: 3,
        original_task: 'Complete implementation',
        completion_claim: 'Implementation complete',
        oracle_feedback: 'Some feedback',
        created_at: '2024-01-22T10:00:00Z',
      };

      expect(verification.oracle_feedback).toBe('Some feedback');
    });
  });

  describe('TodoItem', () => {
    it('should accept valid todo item with pending status', () => {
      const todo: TodoItem = {
        content: 'Test item',
        status: 'pending',
      };

      expect(todo.status).toBe('pending');
    });

    it('should accept valid todo item with in_progress status', () => {
      const todo: TodoItem = {
        content: 'Test item',
        status: 'in_progress',
        activeForm: 'Testing item',
      };

      expect(todo.status).toBe('in_progress');
      expect(todo.activeForm).toBe('Testing item');
    });

    it('should accept valid todo item with completed status', () => {
      const todo: TodoItem = {
        content: 'Test item',
        status: 'completed',
      };

      expect(todo.status).toBe('completed');
    });
  });

  describe('TodosState', () => {
    it('should accept valid todos state structure', () => {
      const state: TodosState = {
        todos: [
          { content: 'Task 1', status: 'completed' },
          { content: 'Task 2', status: 'in_progress', activeForm: 'Working on Task 2' },
          { content: 'Task 3', status: 'pending' },
        ],
      };

      expect(state.todos).toHaveLength(3);
    });
  });

  describe('HudData', () => {
    it('should accept valid hud data structure with null values', () => {
      const data: HudData = {
        contextPercent: null,
        ralph: null,
        ultrawork: null,
        ralphVerification: null,
        todos: null,
        runningAgents: 0,
        backgroundTasks: 0,
        activeSkill: null,
      };

      expect(data.contextPercent).toBeNull();
      expect(data.runningAgents).toBe(0);
    });

    it('should accept valid hud data structure with populated values', () => {
      const data: HudData = {
        contextPercent: 75,
        ralph: {
          active: true,
          iteration: 2,
          max_iterations: 5,
          completion_promise: 'Promise',
          prompt: 'Prompt',
          started_at: '2024-01-22T10:00:00Z',
          linked_ultrawork: true,
        },
        ultrawork: {
          active: true,
          started_at: '2024-01-22T10:00:00Z',
          original_prompt: 'Prompt',
          reinforcement_count: 1,
          linked_to_ralph: true,
        },
        ralphVerification: null,
        todos: { completed: 3, total: 5 },
        runningAgents: 2,
        backgroundTasks: 1,
        activeSkill: 'prometheus',
      };

      expect(data.contextPercent).toBe(75);
      expect(data.ralph?.iteration).toBe(2);
      expect(data.todos?.completed).toBe(3);
    });
  });

  describe('ANSI', () => {
    it('should export ANSI color codes', () => {
      expect(ANSI.reset).toBe('\x1b[0m');
      expect(ANSI.green).toBe('\x1b[32m');
      expect(ANSI.yellow).toBe('\x1b[33m');
      expect(ANSI.red).toBe('\x1b[31m');
      expect(ANSI.bold).toBe('\x1b[1m');
    });
  });
});
