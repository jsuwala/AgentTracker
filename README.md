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

## Workflow:

### Generate a PRD

Prompt:
```
Use the PRD skill to create a PRD that ... .
```

### Review a PRD

Prompt:
```
Use the PRDReview skill to review this PRD: AgentTracker/PRDs/prd-find-sites-to-archive.md
```

### Generate prd.json from PRD

Prompt:
```
Use the PRDToAgentTracking skill to convert this PRD to prd.json: AgentTracker/PRDs/prd-find-sites-to-archive.md
```

### Review prd.json

Prompt:
```
Use the PRDJsonReviewer skill to review the prd.json against this original PRD: AgentTracker/PRDs/prd-find-sites-to-archive.md
```

### Make sure you are working on the main branch

Before running `run-agent-loop-claude.sh`, ensure that previous branches have been merged into main and that the working directory is in the main branch.

### Run the loop

Check out the number of user stories in prd.json and run
```bash
./AgentTracker/run-agent-loop-claude.sh <<num-user-stories>>
```


## Reference

Based initally (but then heavily modified) on https://github.com/aptabase/aptabase/blob/main/scripts/ralph/ralph.sh 
