# AgentTracker
AI Agent Software Development skills and scripts

## Install / Update

Run this from the target repository to install or update the AgentTracker assets:

```bash
curl -fsSL https://raw.githubusercontent.com/jsuwala/AgentTracker/main/InstallOrUpdate.sh | bash
```

The installer manages these files in the target repo:

- `.claude/skills/PRD/SKILL.md`
- `.claude/skills/PRDJsonReviewer/SKILL.md`
- `.claude/skills/PRDReview/SKILL.md`
- `.claude/skills/PRDToAgentTracking/SKILL.md`
- `AgentTracker/prompt.md`
- `AgentTracker/run-agent-loop-claude.sh`

The installer also runs:

- `npm install -g @playwright/cli@latest`
- `playwright-cli install --skills`

Prerequisites:

- `npm` available on `PATH`
- Node.js 18 or newer for `@playwright/cli`

It is safe to re-run and only updates files whose contents changed.

## Reference

Based initally (but then heavily modified) on https://github.com/aptabase/aptabase/blob/main/scripts/ralph/ralph.sh 
