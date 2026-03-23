---
name: PRDJsonReviewer
description: Reviews Product Requirements Documents (PRDs) in JSON format for completeness and internal coherence that is understandable by a junior developer. Triggers on: review prd.json, update prd.json ."
---

# PRD.json Reviewer

Steps to follow:
1. Fully read the AgentTracker/active/prd.json file
2. Fully read the given PRD markdown file specified by the user
3. Compare the prd.json file to the PRD markdown file. The prd.json file was generated from the PRD markdown file and may have gaps or inconsistencies. The prd.json file will not be an exact match to the PRD markdown file, as large tasks or user stories may be broken down in the prd.json file. However all user stories and functional requirements in the PRD markdown file must be in the prd.json. If details in the PRD markdown file are not in the prd.json, the prd.json must be updated. Note the functional requirements to not have their own stories, but must be integrated into other stories.
  - Do not create stand-alone functional requirement stories. Instead integrate all functional requirements into other user stories.
4. Update the prd.json file using the PRD markdown file as the source of truth. Do not make changes to the PRD markdown file.

## Required prd.json Format

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
