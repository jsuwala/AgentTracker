---
name: PRDReviewer
description: Reviews Product Requirements Documents (PRDs) for completeness and internal coherence that is understandable by a junior developer. Triggers on: review this prd, update the prd."
---

# PRD Reviewer

## Purpose
Review a PRD for best practices *specifically* for implementation by agentic coding tools (Claude Code, OpenAI Codex) and return:
1) a structured review using the PRD Review Rubric, and
2) a **menu of change options** the user can select to update the PRD.


## Output contract (must follow)
Your response MUST contain these sections in order:

1. **Change Menu (Selectable Options)**
   - A description of the issue found in the PRD
   - List 2-4 options that can solve the identified issue. .
    - Each option MUST include:
      - **UserResponseCode** (e.g., `1A`, `1B`, `2A`)
      - **Title**
      - **Rationale** (1–3 sentences)

2. **How to Apply**
   - Ask the user to reply with:
     - selected option codes (e.g., “Apply 1A, 2C, 4B”), or
     - “Apply all Recommended”
   - State that you will then produce the updated PRD with only the selected changes.


## PRD Review rubric

### A. Structure & navigation
- Clear title, background, problem statement
- Goals and non-goals explicitly stated
- Glossary / definitions for key terms
- Numbered headings / stable anchors for referencing sections

### B. Requirements quality
- Requirements use “must/shall” and avoid vague terms (“fast”, “intuitive”) unless quantified
- Acceptance criteria per feature / per flow (Given/When/Then preferred)
- Explicit error states and recovery
- Permissions/roles and access control spelled out

### C. Flows & edge cases
- Primary user journeys
- Alternate paths, empty states, retries/timeouts, offline/latency if relevant
- Data lifecycle and state transitions (create/update/delete/archive)

### D. Interfaces & data contracts
- API endpoints / events / messages (if applicable)
- Schemas and examples (request/response, payloads)
- Compatibility and versioning expectations
- User interface specifications

### E. Non-functional requirements (NFRs)
- Performance targets (p95 latency, throughput, batch windows, etc.)
- Security/privacy (PII handling, authn/authz, audit logging)
- Observability (logs, metrics, traces, dashboards, alerts)
- Accessibility and localization (if UI)
- Compliance constraints (if any)

### F. Delivery & operations
- Rollout plan, feature flags, staged release
- Migration/backfill strategy (if data changes)
- Monitoring + rollback
- Support readiness (runbook notes)

### G. Risks & dependencies
- External dependencies (teams, vendors, systems)
- Known risks, mitigations, and decision log
- Open questions explicitly listed (with owners if provided)

### H. User story complexity and size

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