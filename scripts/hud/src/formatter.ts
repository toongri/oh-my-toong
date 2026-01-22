import { ANSI, type HudData } from './types.js';

function colorize(text: string, color: string): string {
  return `${color}${text}${ANSI.reset}`;
}

function getContextColor(percent: number): string {
  if (percent > 85) return ANSI.red;
  if (percent > 70) return ANSI.yellow;
  return ANSI.green;
}

function getRalphColor(iteration: number, max: number): string {
  if (iteration >= max) return ANSI.red;
  if (iteration > max * 0.7) return ANSI.yellow;
  return ANSI.green;
}

export function formatStatusLine(data: HudData): string {
  const parts: string[] = [];

  // Always show prefix
  parts.push(colorize('[OMC]', ANSI.bold));

  // Ralph status with verification
  if (data.ralph?.active) {
    const color = getRalphColor(data.ralph.iteration, data.ralph.max_iterations);
    let ralphText = `ralph:${data.ralph.iteration}/${data.ralph.max_iterations}`;

    // Add verification status if pending
    if (data.ralphVerification?.pending) {
      const v = data.ralphVerification;
      ralphText += ` \u2713${v.verification_attempts}/${v.max_verification_attempts}`;
    }

    parts.push(colorize(ralphText, color));
  }

  // Ultrawork status
  if (data.ultrawork?.active) {
    parts.push(colorize('ultrawork', ANSI.green));
  }

  // Context window percentage (most reliable)
  if (data.contextPercent !== null) {
    const percent = Math.min(100, Math.round(data.contextPercent));
    const color = getContextColor(percent);
    parts.push(colorize(`ctx:${percent}%`, color));
  }

  // Running agents
  if (data.runningAgents > 0) {
    parts.push(colorize(`agents:${data.runningAgents}`, ANSI.green));
  }

  // Background tasks
  if (data.backgroundTasks > 0) {
    parts.push(colorize(`bg:${data.backgroundTasks}`, ANSI.green));
  }

  // Todos completion
  if (data.todos) {
    const { completed, total } = data.todos;
    const color = completed === total ? ANSI.green : ANSI.yellow;
    parts.push(colorize(`todos:${completed}/${total}`, color));
  }

  // Active skill (truncate to 15 chars)
  if (data.activeSkill) {
    const skill = data.activeSkill.length > 15
      ? data.activeSkill.substring(0, 15)
      : data.activeSkill;
    parts.push(colorize(`skill:${skill}`, ANSI.green));
  }

  return parts.join(' | ');
}

export function formatMinimalStatus(contextPercent: number | null): string {
  const parts = [colorize('[OMC]', ANSI.bold)];

  if (contextPercent !== null) {
    const percent = Math.min(100, Math.round(contextPercent));
    const color = getContextColor(percent);
    parts.push(colorize(`ctx:${percent}%`, color));
  } else {
    parts.push('ready');
  }

  return parts.join(' ');
}
