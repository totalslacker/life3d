# Contributing to Life3D

## How Development Works

This project uses [Fabrik](https://github.com/tenaciousvc/fabrik) to orchestrate
development. Issues flow through a pipeline of stages — Specify, Research, Plan,
Implement, Review, Validate — each driven by Claude Code with stage-specific skills.

## How You Can Contribute

### Steer the Agent

File a GitHub issue with the `agent-input` label. The agent reads these during
pipeline stages and prioritizes them. Be specific about what you want — the
agent responds better to concrete problems than vague suggestions.

### Direct Code Contributions

Pull requests are welcome. Keep in mind:

- **Don't modify `IDENTITY.md`** — it's the project's constitution
- **Don't delete journal entries** — JOURNAL.md is append-only
- **Tests are required** for code changes once the project has a test suite

## Project Structure

```
life3d/
├── .claude/CLAUDE.md      # Instructions for Claude Code workers
├── .fabrik/
│   ├── config.yaml        # Fabrik pipeline configuration
│   ├── stages/            # Stage definitions (specify, research, plan, etc.)
│   └── plugin/            # Claude Code plugin with stage skills
├── IDENTITY.md            # Project constitution (immutable)
├── PERSONALITY.md         # Agent voice and communication style
├── SPECS.md               # Project specification
├── ROADMAP.md             # Priorities and milestones
├── JOURNAL.md             # Session log (append-only)
├── LEARNINGS.md           # Technical insights
├── NEXT_STEPS.md          # Structured planning intent
└── README.md              # Project overview
```
