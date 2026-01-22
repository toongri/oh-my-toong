// src/stdin.ts
async function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("readable", () => {
      let chunk;
      while ((chunk = process.stdin.read()) !== null) {
        data += chunk;
      }
    });
    process.stdin.on("end", () => {
      try {
        const parsed = JSON.parse(data);
        resolve(parsed);
      } catch {
        resolve(null);
      }
    });
    setTimeout(() => {
      if (!data) resolve(null);
    }, 100);
  });
}

// src/state.ts
import { readFile, readdir } from "fs/promises";
import { join } from "path";
import { homedir } from "os";
async function readJsonFile(path) {
  try {
    const content = await readFile(path, "utf8");
    return JSON.parse(content);
  } catch {
    return null;
  }
}
async function findStateFile(cwd, filename) {
  const localPath = join(cwd, ".claude", "sisyphus", filename);
  const local = await readJsonFile(localPath);
  if (local) return local;
  const globalPath = join(homedir(), ".claude", filename);
  return readJsonFile(globalPath);
}
async function readRalphState(cwd) {
  return findStateFile(cwd, "ralph-state.json");
}
async function readUltraworkState(cwd) {
  return findStateFile(cwd, "ultrawork-state.json");
}
async function readRalphVerification(cwd) {
  const verification = await findStateFile(cwd, "ralph-verification.json");
  if (verification?.created_at) {
    const createdAt = new Date(verification.created_at).getTime();
    const now = Date.now();
    const hours24 = 24 * 60 * 60 * 1e3;
    if (now - createdAt > hours24) {
      return null;
    }
  }
  return verification;
}
async function readTodos(cwd) {
  const allTodos = [];
  const sisyphusPath = join(cwd, ".claude", "sisyphus", "todos.json");
  const sisyphusTodos = await readJsonFile(sisyphusPath);
  if (sisyphusTodos?.todos) {
    allTodos.push(...sisyphusTodos.todos);
  }
  const localPath = join(cwd, ".claude", "todos.json");
  const localTodos = await readJsonFile(localPath);
  if (localTodos?.todos) {
    allTodos.push(...localTodos.todos);
  }
  const globalTodosDir = join(homedir(), ".claude", "todos");
  try {
    const files = await readdir(globalTodosDir);
    for (const file of files) {
      if (file.endsWith(".json")) {
        const fileTodos = await readJsonFile(join(globalTodosDir, file));
        if (fileTodos?.todos) {
          allTodos.push(...fileTodos.todos);
        }
      }
    }
  } catch {
  }
  if (allTodos.length === 0) return null;
  const completed = allTodos.filter((t) => t.status === "completed").length;
  return { completed, total: allTodos.length };
}
async function readBackgroundTasks() {
  const tasksDir = join(homedir(), ".claude", "background-tasks");
  try {
    const files = await readdir(tasksDir);
    return files.filter((f) => f.endsWith(".json")).length;
  } catch {
    return 0;
  }
}

// src/transcript.ts
import { createReadStream } from "fs";
import { createInterface } from "readline";
async function parseTranscript(transcriptPath) {
  const result = {
    runningAgents: 0,
    activeSkill: null
  };
  try {
    const fileStream = createReadStream(transcriptPath);
    const rl = createInterface({
      input: fileStream,
      crlfDelay: Infinity
    });
    const agentIds = /* @__PURE__ */ new Set();
    for await (const line of rl) {
      try {
        const entry = JSON.parse(line);
        if (entry.tool === "Task" || entry.toolName === "Task") {
          if (entry.status === "started" || entry.state === "running") {
            agentIds.add(line);
          } else if (entry.status === "completed" || entry.state === "done") {
            agentIds.delete(line);
          }
        }
        if (entry.tool === "Skill" || entry.toolName === "Skill") {
          if (entry.name) {
            result.activeSkill = entry.name;
          }
        }
      } catch {
      }
    }
    result.runningAgents = agentIds.size;
  } catch {
  }
  return result;
}

// src/types.ts
var ANSI = {
  reset: "\x1B[0m",
  green: "\x1B[32m",
  yellow: "\x1B[33m",
  red: "\x1B[31m",
  bold: "\x1B[1m"
};

// src/formatter.ts
function colorize(text, color) {
  return `${color}${text}${ANSI.reset}`;
}
function getContextColor(percent) {
  if (percent > 85) return ANSI.red;
  if (percent > 70) return ANSI.yellow;
  return ANSI.green;
}
function getRalphColor(iteration, max) {
  if (iteration >= max) return ANSI.red;
  if (iteration > max * 0.7) return ANSI.yellow;
  return ANSI.green;
}
function formatStatusLine(data) {
  const parts = [];
  parts.push(colorize("[OMC]", ANSI.bold));
  if (data.ralph?.active) {
    const color = getRalphColor(data.ralph.iteration, data.ralph.max_iterations);
    let ralphText = `ralph:${data.ralph.iteration}/${data.ralph.max_iterations}`;
    if (data.ralphVerification?.pending) {
      const v = data.ralphVerification;
      ralphText += ` \u2713${v.verification_attempts}/${v.max_verification_attempts}`;
    }
    parts.push(colorize(ralphText, color));
  }
  if (data.ultrawork?.active) {
    parts.push(colorize("ultrawork", ANSI.green));
  }
  if (data.contextPercent !== null) {
    const percent = Math.min(100, Math.round(data.contextPercent));
    const color = getContextColor(percent);
    parts.push(colorize(`ctx:${percent}%`, color));
  }
  if (data.runningAgents > 0) {
    parts.push(colorize(`agents:${data.runningAgents}`, ANSI.green));
  }
  if (data.backgroundTasks > 0) {
    parts.push(colorize(`bg:${data.backgroundTasks}`, ANSI.green));
  }
  if (data.todos) {
    const { completed, total } = data.todos;
    const color = completed === total ? ANSI.green : ANSI.yellow;
    parts.push(colorize(`todos:${completed}/${total}`, color));
  }
  if (data.activeSkill) {
    const skill = data.activeSkill.length > 15 ? data.activeSkill.substring(0, 15) : data.activeSkill;
    parts.push(colorize(`skill:${skill}`, ANSI.green));
  }
  return parts.join(" | ");
}
function formatMinimalStatus(contextPercent) {
  const parts = [colorize("[OMC]", ANSI.bold)];
  if (contextPercent !== null) {
    const percent = Math.min(100, Math.round(contextPercent));
    const color = getContextColor(percent);
    parts.push(colorize(`ctx:${percent}%`, color));
  } else {
    parts.push("ready");
  }
  return parts.join(" ");
}

// src/index.ts
async function main() {
  try {
    const input = await readStdin();
    if (!input) {
      console.log(formatMinimalStatus(null));
      return;
    }
    const cwd = input.cwd || process.cwd();
    const [ralph, ultrawork, ralphVerification, todos, backgroundTasks, transcriptData] = await Promise.all([
      readRalphState(cwd),
      readUltraworkState(cwd),
      readRalphVerification(cwd),
      readTodos(cwd),
      readBackgroundTasks(),
      input.transcript_path ? parseTranscript(input.transcript_path) : Promise.resolve({ runningAgents: 0, activeSkill: null })
    ]);
    const hudData = {
      contextPercent: input.context_window?.used_percentage ?? null,
      ralph,
      ultrawork,
      ralphVerification,
      todos,
      runningAgents: transcriptData.runningAgents,
      backgroundTasks,
      activeSkill: transcriptData.activeSkill
    };
    console.log(formatStatusLine(hudData));
  } catch (error) {
    console.log(formatMinimalStatus(null));
  }
}
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
export {
  main
};
