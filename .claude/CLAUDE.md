# CLAUDE.md — Fabrik Project Instructions

This repository uses [Fabrik](https://github.com/tenaciousvc/fabrik), an SDLC
pipeline orchestrator that drives GitHub issues through stages (Specify →
Research → Plan → Implement → Review → Validate → Done) using Claude Code.

## For Fabrik Stage Workers

You are running a Fabrik stage. Your work is guided by the stage skill injected
by the Fabrik engine. Follow it.

### Key Files to Read First

1. **IDENTITY.md** — Who this project is. Immutable. Read it, internalize it.
2. **SPECS.md** — What we're building.
3. **ROADMAP.md** — Current priorities and milestones.
4. **JOURNAL.md** — Recent history. Check what was tried before.
5. **LEARNINGS.md** — Cached technical knowledge.
6. **PERSONALITY.md** — Voice and communication style guidelines.
7. **NEXT_STEPS.md** — Structured planning intent from the last session.

### Safety Rules

- **Never modify IDENTITY.md.** It's the project's constitution.
- **Every change must pass the build.** If it breaks, fix it or revert.
- **Never delete existing tests.** Tests protect the project from regressions.
- **Commit frequently.** Small, atomic commits with descriptive messages.

### Build & Test Commands

```bash
# Build for visionOS Simulator
xcodebuild -project Life3D.xcodeproj -scheme Life3D \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' build

# The visionOS Simulator runs fine — boot it and validate visual changes
# before declaring UI/RealityKit fixes complete. Build-only verification is
# not sufficient for features that depend on rendering or VFX state.
# Write logic-only tests (no RealityKit dependencies in test targets).
```

### Work Tracking

Work is tracked via GitHub issues on this repository. Fabrik manages the
pipeline — issues move through project board columns that correspond to stages.

### Before You Push

Before pushing your branch, you MUST:

1. Write a journal entry at the TOP of JOURNAL.md using this format:
   ```
   ## YYYY-MM-DD HH:MM TZ

   **Goal**: What you set out to do this session.

   <description of what you did, what worked, what didn't>

   **Next Steps**: What should be tackled next.
   ```
2. Update ROADMAP.md if you completed any roadmap items
3. Update LEARNINGS.md if you discovered technical insights
4. Update NEXT_STEPS.md if priorities have changed

Include journal/learnings updates in the SAME commit as your code change.
Do NOT make a separate commit for state file updates.

### Discovered Issues

If you find bugs or improvements outside your current scope, file a GitHub
issue. Do NOT fix unrelated issues in your current branch.
