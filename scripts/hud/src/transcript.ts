import { createReadStream } from 'fs';
import { createInterface } from 'readline';

interface TranscriptEntry {
  type?: string;
  tool?: string;
  toolName?: string;
  name?: string;
  status?: string;
  state?: string;
}

export async function parseTranscript(transcriptPath: string): Promise<{
  runningAgents: number;
  activeSkill: string | null;
}> {
  const result = {
    runningAgents: 0,
    activeSkill: null as string | null,
  };

  try {
    const fileStream = createReadStream(transcriptPath);
    const rl = createInterface({
      input: fileStream,
      crlfDelay: Infinity,
    });

    const agentIds = new Set<string>();

    for await (const line of rl) {
      try {
        const entry = JSON.parse(line) as TranscriptEntry;

        // Count running agents (Task tool calls that haven't completed)
        if (entry.tool === 'Task' || entry.toolName === 'Task') {
          if (entry.status === 'started' || entry.state === 'running') {
            agentIds.add(line); // Use line as unique identifier
          } else if (entry.status === 'completed' || entry.state === 'done') {
            agentIds.delete(line);
          }
        }

        // Track active skill
        if (entry.tool === 'Skill' || entry.toolName === 'Skill') {
          if (entry.name) {
            result.activeSkill = entry.name;
          }
        }
      } catch {
        // Skip malformed lines
      }
    }

    result.runningAgents = agentIds.size;
  } catch {
    // File doesn't exist or can't be read
  }

  return result;
}
