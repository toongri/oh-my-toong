# Oh-My-Toong HUD

A statusLine-based Heads-Up Display for Claude Code, showing real-time session status.

## Features

- **Context Window Usage**: See how much of your context is used
- **Ralph Loop Status**: Track iteration progress with color-coded warnings
- **Running Agents**: Count of active subagents
- **Background Tasks**: Count of background processes
- **Todo Progress**: Track task completion
- **Active Skill**: Currently executing skill name

## Display Format

```
[OMC] ralph:3/10 | ctx:67% | agents:2 | bg:1 | todos:2/5 | skill:prometheus
```

### Color Coding

| Color | Meaning |
|-------|---------|
| Green | Normal/healthy |
| Yellow | Warning (ctx >70%, ralph >7) |
| Red | Critical (ctx >85%, ralph maxed) |

## Installation

### Using /hud setup (Recommended)

In Claude Code, run:
```
/hud setup
```

Then restart Claude Code.

### Manual Installation

1. Build the project:
   ```bash
   cd hooks/hud
   npm install
   npm run build
   ```

2. Copy to Claude directory:
   ```bash
   mkdir -p ~/.claude/hud
   cp dist/index.js ~/.claude/hud/omc-hud.mjs
   ```

3. Edit `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "node ~/.claude/hud/omc-hud.mjs"
     }
   }
   ```

4. Restart Claude Code.

## Uninstallation

To restore previous statusLine configuration:
```
/hud restore
```

Or manually:
1. Remove `statusLine` from `~/.claude/settings.json`
2. Delete `~/.claude/hud/` directory

## Data Sources

| Feature | Source |
|---------|--------|
| Context % | stdin JSON from Claude Code |
| Ralph status | `.claude/sisyphus/ralph-state.json` (includes oracle_feedback) |
| Todos | `.claude/sisyphus/todos.json` + `~/.claude/todos/*.json` |
| Agents | `transcript.jsonl` parsing |
| Skills | `transcript.jsonl` parsing |

## State File Locations

The HUD checks for state files in priority order:

1. `$CWD/.claude/sisyphus/*.json` (project-local)
2. `~/.claude/*.json` (global fallback)

## Requirements

- **Node.js**: v18+ (for ESM support)
- **Platform**: macOS, Linux (Windows untested)
- **Claude Code**: With statusLine support

## Performance

- Execution time: <100ms
- Memory usage: <50MB
- No external network calls
- Streams large transcript files

## Graceful Degradation

The HUD always shows something. If data is unavailable:

| Scenario | Behavior |
|----------|----------|
| No state files | Feature shown as inactive |
| Malformed stdin | Shows `[OMC] ready` |
| Transcript missing | Skips agent/skill tracking |
| Stale verification (>24h) | Treated as inactive |

Minimum output: `[OMC] ctx:42%`

## Development

### Project Structure

```
hooks/hud/
├── src/
│   ├── index.ts          # Main entry point
│   ├── stdin.ts          # stdin JSON parsing
│   ├── transcript.ts     # transcript.jsonl parsing
│   ├── state.ts          # State file reading
│   ├── formatter.ts      # Status line formatting
│   └── types.ts          # TypeScript definitions
├── dist/                 # Compiled output
├── package.json
├── tsconfig.json
└── README.md
```

### Building

```bash
npm install
npm run build
```

### Testing

```bash
npm test
```

## License

Part of oh-my-toong project.
