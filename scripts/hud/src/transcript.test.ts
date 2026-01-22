import { parseTranscript } from './transcript.js';
import { mkdir, writeFile, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';

describe('parseTranscript', () => {
  const testDir = join(tmpdir(), 'hud-transcript-test-' + Date.now());

  beforeAll(async () => {
    await mkdir(testDir, { recursive: true });
  });

  afterAll(async () => {
    await rm(testDir, { recursive: true, force: true });
  });

  it('should return default values when file does not exist', async () => {
    const nonExistentPath = join(testDir, 'nonexistent.jsonl');

    const result = await parseTranscript(nonExistentPath);

    expect(result.runningAgents).toBe(0);
    expect(result.activeSkill).toBeNull();
  });

  it('should track active skill from Skill tool calls', async () => {
    const transcriptPath = join(testDir, 'skill-transcript.jsonl');
    const lines = [
      JSON.stringify({ tool: 'Skill', name: 'prometheus', status: 'started' }),
    ];
    await writeFile(transcriptPath, lines.join('\n'));

    const result = await parseTranscript(transcriptPath);

    expect(result.activeSkill).toBe('prometheus');
  });

  it('should track active skill using toolName field', async () => {
    const transcriptPath = join(testDir, 'skill-toolname-transcript.jsonl');
    const lines = [
      JSON.stringify({ toolName: 'Skill', name: 'sisyphus', status: 'started' }),
    ];
    await writeFile(transcriptPath, lines.join('\n'));

    const result = await parseTranscript(transcriptPath);

    expect(result.activeSkill).toBe('sisyphus');
  });

  it('should count running agents from Task tool calls', async () => {
    const transcriptPath = join(testDir, 'agents-transcript.jsonl');
    const lines = [
      JSON.stringify({ tool: 'Task', status: 'started', id: 'agent1' }),
      JSON.stringify({ tool: 'Task', status: 'running', id: 'agent2' }),
    ];
    await writeFile(transcriptPath, lines.join('\n'));

    const result = await parseTranscript(transcriptPath);

    expect(result.runningAgents).toBeGreaterThanOrEqual(0);
  });

  it('should skip malformed JSON lines', async () => {
    const transcriptPath = join(testDir, 'malformed-transcript.jsonl');
    const lines = [
      '{ invalid json }',
      JSON.stringify({ tool: 'Skill', name: 'explore' }),
    ];
    await writeFile(transcriptPath, lines.join('\n'));

    const result = await parseTranscript(transcriptPath);

    expect(result.activeSkill).toBe('explore');
  });

  it('should return last active skill when multiple skills are invoked', async () => {
    const transcriptPath = join(testDir, 'multiple-skills-transcript.jsonl');
    const lines = [
      JSON.stringify({ tool: 'Skill', name: 'prometheus' }),
      JSON.stringify({ tool: 'Skill', name: 'sisyphus' }),
      JSON.stringify({ tool: 'Skill', name: 'oracle' }),
    ];
    await writeFile(transcriptPath, lines.join('\n'));

    const result = await parseTranscript(transcriptPath);

    expect(result.activeSkill).toBe('oracle');
  });
});
