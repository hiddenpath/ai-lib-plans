---
# AI-Lib Plans - Private Project Planning Repository

**Status**: Active
**Last Updated**: 2026-02-27
**Purpose**: Structured project planning, task tracking, and work documentation for the ai-lib ecosystem

## Overview

This repository contains all planning, task tracking, and work documentation
for the ai-lib ecosystem projects:

- **ai-protocol** - Provider-agnostic protocol specification
- **ai-lib-rust** - Rust runtime implementation
- **ai-lib-python** - Python runtime implementation
- **ai-lib-ts** - TypeScript/JavaScript runtime implementation
- **ai-protocol-mock** - Mock server for testing

## Structure

```
ai-lib-plans/
├── active/                    # Current work in progress
│   ├── projects/             # Project-specific tracking
│   │   ├── ai-protocol/
│   │   ├── ai-lib-rust/
│   │   ├── ai-lib-python/
│   │   ├── ai-lib-ts/
│   │   └── ai-protocol-mock/
│   ├── releases/             # Release schedules and planning
│   │   └── 2026/
│   │       ├── Q1/
│   │       └── Q2/
│   └── standup/              # Daily standup and retrospectives
│       ├── daily/
│       └── retrospectives/
├── archive/                  # Completed work
│   ├── completed-projects/
│   ├── completed-tasks/
│   └── meeting-notes/
├── reviews/                  # Review records
│   ├── code-reviews/
│   ├── design-reviews/
│   └── triage/
├── specs/                    # Detailed specifications
│   ├── feature-specs/
│   ├── api-specs/
│   └── integration-specs/
├── metrics/                  # Project metrics and velocity
├── scripts/                  # Automation scripts
└── templates/                # YAML templates for tasks/milestones
```

## Memory System

| Component | Path | Purpose |
|-----------|------|---------|
| **Long-term** | [MEMORY.md](MEMORY.md) | Curated architecture decisions, conventions, learnings |
| **Short-term** | [active/standup/daily/](active/standup/daily/) | Daily append-only logs |
| **Flush flow** | [memory/README.md](memory/README.md) | How to extract durable facts from standups into MEMORY.md |

AI agents: use `memory_get` or `memory_search` skill to recall context.

## Quick Start

### View Current Tasks

```bash
# Show active tasks for all projects
ls active/projects/*/tasks/

# Show specific project tasks
ls active/projects/ai-protocol/tasks/
```

### View Daily Standups

```bash
# View recent daily summaries
ls active/standup/daily/ | tail -10

# View today's standup
cat active/standup/daily/2026-02-27.md
```

### View Release Schedule

```bash
# Current quarter release plans
ls active/releases/2026/Q1/
```

## Task Format

All tasks follow this YAML structure:

```yaml
---
id: "<PROJECT>-<SEQUENCE>"
title: "Task Title"
status: "pending"  # pending, in_progress, blocked, completed
priority: "medium"  # low, medium, high, critical
assignee: "@username"
project: "ai-protocol"
milestone: "v0.8.0"
labels:
  - "feature"
  - "api"
created: "2026-02-27"
updated: "2026-02-27"

description: |
  Detailed description of the task.

acceptance_criteria:
  - Criterion 1
  - Criterion 2
  - Criterion 3

dependencies:
  - "XXX-<dependency-task-id>"

related_issues:
  - "https://github.com/hiddenpath/ai-protocol/issues/123"

references:
  - "https://github.com/hiddenpath/ai-protocol/pull/456"

estimated_hours: 8
actual_hours: null

blocks: []
blocked_by: []

completion_notes: |
  Notes added when task is completed.
```

## Current Status

### Active Projects

| Project | Status | Next Milestone | Progress |
|---------|--------|----------------|----------|
| ai-protocol | Active | v0.8.0 | 75% |
| ai-lib-rust | Active | v0.9.0 | 60% |
| ai-lib-python | Active | v0.8.0 | 70% |
| ai-lib-ts | Active | v0.5.0 | 50% |
| ai-protocol-mock | Active | v0.2.0 | 90% |

### Recent Activity

- 2026-02-27: Created ai-lib-constitution and ai-lib-plans repositories
- 2026-02-26: Working on V2 protocol alignment across runtimes
- 2026-02-25: MCP integration and tool bridge implementation

## Workflows

### Creating a New Task

1. Copy template from `templates/task-template.yaml`
2. Fill in all required fields
3. Save to appropriate project's `tasks/` directory
4. Update project milestone if needed

### Daily Standup Format

See `templates/daily-standup-template.md` for format.

### Release Planning

- Quarter-specific planning in `active/releases/YYYY/QX/`
- Feature freeze dates documented
- Release candidate schedules tracked

## Import Historical Data

Historical documentation imported from local workspace:

### AI Protocol Tasks
- `archive/ai-protocol-tasks/` - Contains AI_PROTOCOL_TASKS_PHASED.md
- Original task breakdowns and requirements analysis

### Historical Roadmaps
- `archive/historical-roadmaps/ai-protocol-v4-import.md` - Migration record for `AI-Protocol项目研发计划_v4.md`
- `active/projects/ai-protocol/ROADMAP_MASTER.md` - Current master roadmap governance file

### Daily Work Summaries
- `active/standup/daily/` - Contains historical work summaries
- Daily progress tracking and blockers

### Audit Reports
- `reviews/audits/` - Contains code audit reports
- Security and quality assessments

## Integration with Constitution

This repository references rules from `ai-lib-constitution` for:

- Coding standards (RUST-001, PY-001, TS-001)
- Architecture rules (ARCH-001, ARCH-002, ARCH-003)
- Testing requirements (TEST-001)

All development work should comply with constitution rules.

## Metrics

### Velocity (Last 30 Days)

| Project | Tasks Completed | Total Hours | Avg Hours/Task |
|---------|----------------|-------------|----------------|
| ai-protocol | 12 | 48 | 4.0 |
| ai-lib-rust | 8 | 32 | 4.0 |
| ai-lib-python | 10 | 40 | 4.0 |
| ai-lib-ts | 6 | 24 | 4.0 |

### Health Indicators

- **Test Coverage**: All projects > 80%
- **Compliance Pass Rate**: 100% for all runtimes
- **Open Issues**: 23 (across all projects)
- **Blocked Tasks**: 3

## Archive Policy

Items are archived to `archive/` when:

- Projects are completed
- Tasks are completed and verified
- Meeting notes are > 6 months old

Archive is quarterly (end of every quarter).

---

**Maintainer**: hiddenpath
**Format**: YAML for structure, Markdown for documentation
**Privacy**: Private repository - internal use only
