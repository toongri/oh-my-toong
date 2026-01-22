import { formatStatusLine, formatMinimalStatus } from './formatter.js';
import { ANSI, type HudData, type RalphState, type UltraworkState, type RalphVerification } from './types.js';

// Helper to create complete ralph state for tests
function createRalphState(overrides: Partial<RalphState> & Pick<RalphState, 'active' | 'iteration' | 'max_iterations'>): RalphState {
  return {
    completion_promise: 'DONE',
    prompt: 'test prompt',
    started_at: '2025-01-22T10:00:00+09:00',
    linked_ultrawork: false,
    ...overrides,
  };
}

// Helper to create complete ultrawork state for tests
function createUltraworkState(overrides: Partial<UltraworkState> & Pick<UltraworkState, 'active'>): UltraworkState {
  return {
    started_at: '2025-01-22T10:00:00+09:00',
    original_prompt: 'test prompt',
    reinforcement_count: 0,
    linked_to_ralph: false,
    ...overrides,
  };
}

// Helper to create complete ralph verification for tests
function createRalphVerification(overrides: Partial<RalphVerification> & Pick<RalphVerification, 'pending' | 'verification_attempts' | 'max_verification_attempts'>): RalphVerification {
  return {
    original_task: 'test task',
    completion_claim: 'test claim',
    created_at: '2025-01-22T10:00:00+09:00',
    ...overrides,
  };
}

describe('formatStatusLine', () => {
  const emptyData: HudData = {
    contextPercent: null,
    ralph: null,
    ultrawork: null,
    ralphVerification: null,
    todos: null,
    runningAgents: 0,
    backgroundTasks: 0,
    activeSkill: null,
  };

  describe('always shows prefix', () => {
    it('shows [OMC] prefix with bold formatting', () => {
      const result = formatStatusLine(emptyData);
      expect(result).toContain('[OMC]');
      expect(result).toContain(ANSI.bold);
    });
  });

  describe('ralph status', () => {
    it('shows ralph iteration when active', () => {
      const data: HudData = {
        ...emptyData,
        ralph: createRalphState({ active: true, iteration: 3, max_iterations: 10 }),
      };
      const result = formatStatusLine(data);
      expect(result).toContain('ralph:3/10');
    });

    it('does not show ralph when inactive', () => {
      const data: HudData = {
        ...emptyData,
        ralph: createRalphState({ active: false, iteration: 0, max_iterations: 10 }),
      };
      const result = formatStatusLine(data);
      expect(result).not.toContain('ralph');
    });

    it('shows green color when iteration is low', () => {
      const data: HudData = {
        ...emptyData,
        ralph: createRalphState({ active: true, iteration: 2, max_iterations: 10 }),
      };
      const result = formatStatusLine(data);
      expect(result).toContain(ANSI.green);
    });

    it('shows yellow color when iteration is above 70% of max', () => {
      const data: HudData = {
        ...emptyData,
        ralph: createRalphState({ active: true, iteration: 8, max_iterations: 10 }),
      };
      const result = formatStatusLine(data);
      expect(result).toContain(ANSI.yellow);
    });

    it('shows red color when iteration equals max', () => {
      const data: HudData = {
        ...emptyData,
        ralph: createRalphState({ active: true, iteration: 10, max_iterations: 10 }),
      };
      const result = formatStatusLine(data);
      expect(result).toContain(ANSI.red);
    });
  });

  describe('ralph verification', () => {
    it('shows verification status when pending', () => {
      const data: HudData = {
        ...emptyData,
        ralph: createRalphState({ active: true, iteration: 3, max_iterations: 10 }),
        ralphVerification: createRalphVerification({
          pending: true,
          verification_attempts: 1,
          max_verification_attempts: 3,
        }),
      };
      const result = formatStatusLine(data);
      expect(result).toMatch(/ralph:3\/10.*✓1\/3/);
    });

    it('does not show verification when not pending', () => {
      const data: HudData = {
        ...emptyData,
        ralph: createRalphState({ active: true, iteration: 3, max_iterations: 10 }),
        ralphVerification: createRalphVerification({
          pending: false,
          verification_attempts: 1,
          max_verification_attempts: 3,
        }),
      };
      const result = formatStatusLine(data);
      expect(result).not.toContain('✓');
    });
  });

  describe('ultrawork status', () => {
    it('shows ultrawork when active', () => {
      const data: HudData = {
        ...emptyData,
        ultrawork: createUltraworkState({ active: true }),
      };
      const result = formatStatusLine(data);
      expect(result).toContain('ultrawork');
      expect(result).toContain(ANSI.green);
    });

    it('does not show ultrawork when inactive', () => {
      const data: HudData = {
        ...emptyData,
        ultrawork: createUltraworkState({ active: false }),
      };
      const result = formatStatusLine(data);
      expect(result).not.toContain('ultrawork');
    });
  });

  describe('context window percentage', () => {
    it('shows context percentage when available', () => {
      const data: HudData = {
        ...emptyData,
        contextPercent: 42.5,
      };
      const result = formatStatusLine(data);
      expect(result).toContain('ctx:43%');
    });

    it('shows green color when context is below 70%', () => {
      const data: HudData = {
        ...emptyData,
        contextPercent: 50,
      };
      const result = formatStatusLine(data);
      expect(result).toContain(ANSI.green);
    });

    it('shows yellow color when context is above 70%', () => {
      const data: HudData = {
        ...emptyData,
        contextPercent: 75,
      };
      const result = formatStatusLine(data);
      expect(result).toContain(ANSI.yellow);
    });

    it('shows red color when context is above 85%', () => {
      const data: HudData = {
        ...emptyData,
        contextPercent: 90,
      };
      const result = formatStatusLine(data);
      expect(result).toContain(ANSI.red);
    });

    it('caps context at 100%', () => {
      const data: HudData = {
        ...emptyData,
        contextPercent: 150,
      };
      const result = formatStatusLine(data);
      expect(result).toContain('ctx:100%');
    });
  });

  describe('running agents', () => {
    it('shows running agents when greater than 0', () => {
      const data: HudData = {
        ...emptyData,
        runningAgents: 3,
      };
      const result = formatStatusLine(data);
      expect(result).toContain('agents:3');
    });

    it('does not show agents when 0', () => {
      const data: HudData = {
        ...emptyData,
        runningAgents: 0,
      };
      const result = formatStatusLine(data);
      expect(result).not.toContain('agents');
    });
  });

  describe('background tasks', () => {
    it('shows background tasks when greater than 0', () => {
      const data: HudData = {
        ...emptyData,
        backgroundTasks: 2,
      };
      const result = formatStatusLine(data);
      expect(result).toContain('bg:2');
    });

    it('does not show background tasks when 0', () => {
      const data: HudData = {
        ...emptyData,
        backgroundTasks: 0,
      };
      const result = formatStatusLine(data);
      expect(result).not.toContain('bg:');
    });
  });

  describe('todos', () => {
    it('shows todos completion status', () => {
      const data: HudData = {
        ...emptyData,
        todos: { completed: 3, total: 5 },
      };
      const result = formatStatusLine(data);
      expect(result).toContain('todos:3/5');
    });

    it('shows green when all todos completed', () => {
      const data: HudData = {
        ...emptyData,
        todos: { completed: 5, total: 5 },
      };
      const result = formatStatusLine(data);
      expect(result).toContain('todos:5/5');
      expect(result).toContain(ANSI.green);
    });

    it('shows yellow when todos incomplete', () => {
      const data: HudData = {
        ...emptyData,
        todos: { completed: 2, total: 5 },
      };
      const result = formatStatusLine(data);
      expect(result).toContain(ANSI.yellow);
    });
  });

  describe('active skill', () => {
    it('shows active skill name', () => {
      const data: HudData = {
        ...emptyData,
        activeSkill: 'prometheus',
      };
      const result = formatStatusLine(data);
      expect(result).toContain('skill:prometheus');
    });

    it('truncates long skill names to 15 chars', () => {
      const data: HudData = {
        ...emptyData,
        activeSkill: 'verylongskillnamethatexceedslimit',
      };
      const result = formatStatusLine(data);
      // 'verylongskillnamethatexceedslimit'.substring(0, 15) = 'verylongskillna'
      expect(result).toContain('skill:verylongskillna');
      expect(result).not.toContain('verylongskillnamethatexceedslimit');
    });
  });

  describe('separator', () => {
    it('uses pipe separator between elements', () => {
      const data: HudData = {
        ...emptyData,
        contextPercent: 50,
        ultrawork: createUltraworkState({ active: true }),
      };
      const result = formatStatusLine(data);
      expect(result).toContain(' | ');
    });
  });
});

describe('formatMinimalStatus', () => {
  it('shows [OMC] prefix', () => {
    const result = formatMinimalStatus(null);
    expect(result).toContain('[OMC]');
  });

  it('shows ready when no context percent', () => {
    const result = formatMinimalStatus(null);
    expect(result).toContain('ready');
  });

  it('shows context percent when available', () => {
    const result = formatMinimalStatus(42);
    expect(result).toContain('ctx:42%');
  });

  it('applies correct color for context percent', () => {
    const result = formatMinimalStatus(90);
    expect(result).toContain(ANSI.red);
  });

  it('caps context at 100%', () => {
    const result = formatMinimalStatus(150);
    expect(result).toContain('ctx:100%');
  });
});
