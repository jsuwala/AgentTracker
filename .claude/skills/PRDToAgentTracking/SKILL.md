---
name: PRDToAgentTracking
description: "Convert PRDs to prd.json format for autonomous agents to use. Use when you have an existing PRD and need to convert it to AgentTracking JSON format. Triggers on: convert this prd, turn this into agent tracking format, create prd.json from this, agent tracking json."
---

# AgentTracking PRD Converter

Converts existing PRDs to the prd.json format that AgentTracker uses for autonomous execution.

---

## The Job

Take a PRD (markdown file or text) and convert it to `prd.json` in the AgentTracker/active directory.

---

## Output Format

```json
{
  "project": "[Project Name]",
  "branchName": "AgentTracker/[feature-name-kebab-case]",
  "description": "[Feature description from PRD title/intro]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck, Lint and Tests pass"
      ],
      "priority": 1,
      "passes": false
    }
  ]
}
```

---

## Story Size: The Number One Rule

**Each story must be completable in ONE AgentTracker iteration (one context window).**

AgentTracker spawns a fresh Agent instance per iteration with no memory of previous work. If a story is too big, the LLM runs out of context before finishing and produces broken code.

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" - Split into: schema, queries, UI components, filters
- "Add authentication" - Split into: schema, middleware, login UI, session handling
- "Refactor the API" - Split into one story per endpoint or pattern

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Story Ordering: Dependencies First

Stories execute in priority order. Earlier stories must not depend on later ones.

**Correct order:**
1. Application frameworks
2. Schema/database changes (migrations)
3. Server actions / backend logic
4. UI components that use the backend
5. Dashboard/summary views that aggregate data

**Wrong order:**
1. UI component (depends on schema that does not exist yet)
2. Schema change

**IMPORTANT:** order the stories to allow early execution for external verification of progress. Make a functional system first and then add features to that functioning system.

---

## Integrate Functional Requirements into other User Stories: Second Rule

**IMPORTANT** Do not create stand-alone functional requirement stories. Instead integrate all functional requirements into other user stories.

---

## Acceptance Criteria: Must Be Verifiable

Each criterion must be something AgentTracker can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck, Lint and Tests pass"
- "Tests pass"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Always include as final criterion:
```
"Typecheck, Lint and Tests pass"
```

For stories with testable logic, also include:
```
"Tests pass"
```

### For stories that change UI, also include:
```
"Verify in browser using playwright-cli skill"
```

Frontend stories are NOT complete until visually verified. AgentTracker will use the playwright-cli skill to navigate to the page, interact with the UI, and confirm changes work.

---

## Conversion Rules

1. **Each user story becomes one JSON entry**
2. **Functional requirements**: Integrated into user stories (no stand-alone functional requirements)
2. **IDs**: Sequential (US-001, US-002, etc.)
3. **Priority**: Based on dependency order, then document order
4. **All stories**: `passes: false` and empty `notes`
5. **branchName**: Derive from feature name, kebab-case, prefixed with `AgentTracker/`
6. **Always add**: "Typecheck, Lint and Tests pass" to every story's acceptance criteria

---

## Splitting Large PRDs or user stories

If a PRD has big features, split them:

**Original:**
> "Add user notification system"

**Split into:**
1. US-001: Add notifications table to database
2. US-002: Create notification service for sending notifications
3. US-003: Add notification bell icon to header
4. US-004: Create notification dropdown panel
5. US-005: Add mark-as-read functionality
6. US-006: Add notification preferences page

Each is one focused change that can be completed and verified independently.

---

## Example

**Input PRD:**
```markdown
# Task Status Feature

Add ability to mark tasks with different statuses.

## Requirements
- Toggle between pending/in-progress/done on task list
- Filter list by status
- Show status badge on each task
- Persist status in database
```

**Output prd.json:**
```json
{
  "project": "TaskApp",
  "branchName": "AgentTracker/task-status",
  "description": "Task Status Feature - Track task progress with status indicators",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add status field to tasks table",
      "description": "As a developer, I need to store task status in the database.",
      "acceptanceCriteria": [
        "Add status column: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration successfully",
        "Typecheck, Lint and Tests pass"
      ],
      "priority": 1,
      "passes": false
      
    },
    {
      "id": "US-002",
      "title": "Display status badge on task cards",
      "description": "As a user, I want to see task status at a glance.",
      "acceptanceCriteria": [
        "Each task card shows colored status badge",
        "Badge colors: gray=pending, blue=in_progress, green=done",
        "Typecheck, Lint and Tests pass",
        "Verify in browser using playwright-cli skill"
      ],
      "priority": 2,
      "passes": false
    },
    {
      "id": "US-003",
      "title": "Add status toggle to task list rows",
      "description": "As a user, I want to change task status directly from the list.",
      "acceptanceCriteria": [
        "Each row has status dropdown or toggle",
        "Changing status saves immediately",
        "UI updates without page refresh",
        "Typecheck, Lint and Tests pass",
        "Verify in browser using playwright-cli skill"
      ],
      "priority": 3,
      "passes": false
    },
    {
      "id": "US-004",
      "title": "Filter tasks by status",
      "description": "As a user, I want to filter the list to see only certain statuses.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Pending | In Progress | Done",
        "Filter persists in URL params",
        "Typecheck, Lint and Tests pass",
        "Verify in browser using playwright-cli skill"
      ],
      "priority": 4,
      "passes": false
    }
  ]
}
```

---

## Double checking that all PRD functions are in the prd.json

After writing the prd.json, do a second fresh run through to ensure that all functionality in the PRD is reflected in the prd.json output. Do not leave stubs or hanging functionality.

---

## Archiving Previous Runs

**Before writing a new prd.json, check if there is an existing one from a different feature:**

1. Read the current `prd.json` if it exists
2. Check if `branchName` differs from the new feature's branch name
3. If different AND `progress.txt` has content beyond the header:
   - Create archive folder: `AgentTracker/archive/YYYY-MM-DD-feature-name/`
   - Move current `prd.json` and `progress.txt` to archive folder
   - Reset `progress.txt` with fresh header


---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] **Previous run archived** (if prd.json exists with different branchName, archive it first)
- [ ] Each story is completable in one iteration (small enough)
- [ ] Stories are ordered by dependency (schema to backend to UI)
- [ ] Every story has "Typecheck, Lint and Tests pass" as criterion
- [ ] UI stories have "Verify in browser using playwright-cli skill" as criterion
- [ ] Acceptance criteria are verifiable (not vague)
- [ ] No story depends on a later story