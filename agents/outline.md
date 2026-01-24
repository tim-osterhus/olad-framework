# Project — Repository Outline

**Last Updated:** YYYY-MM-DD
**Purpose:** Quick codebase reference for agents. Read this once to understand the project shape.

---

## Executive Summary

<Brief summary of the system: what it does, who uses it, and the key runtime constraints.>

**Key Principles:**
- <Constraint or principle 1>
- <Constraint or principle 2>
- <Constraint or principle 3>

---

## Repository Structure Overview

```
project-root/
├── src/                 # Core application code
├── services/            # Supporting services or workers
├── infra/               # Deployment assets (compose, k8s, terraform)
├── agents/              # Agent workflow & task management
├── tests/               # Automated tests
├── docs/                # Product and developer docs
└── .github/             # CI/CD workflows
```

---

## Core Technology Stack

### Backend
- <Primary language/framework>
- <API style: REST/GraphQL/etc>
- <Auth provider or strategy>

### Frontend (if applicable)
- <UI framework>
- <Build tool>
- <State management>

### Data
- <Primary database>
- <Caching/queueing>
- <Search/indexing>

### Infrastructure
- <Container/orchestrator>
- <Logging/metrics>
- <Secrets management>

---

## Directory Deep Dive

### `src/` — Core Application

**Purpose:** Primary business logic and product features.

**Key Files:**
```
src/
├── main.*              # Application entrypoint
├── config.*            # Configuration loading
├── routes/             # API routing
├── services/           # Business logic modules
└── models/             # Data models and schemas
```

### `infra/` — Deployment

**Purpose:** Deployment manifests, container definitions, and environment templates.

**Key Files:**
```
infra/
├── compose/            # Docker Compose files
├── k8s/                # Kubernetes manifests
└── scripts/            # Infra helpers
```

### `agents/` — Agent Workflow

**Purpose:** Task prompts, runbooks, and audit trail for agentic development.

**Key Files:**
```
agents/
├── _start.md           # Builder entrypoint
├── _check.md           # QA entrypoint
├── prompts/            # Prompt artifacts
├── tasks.md            # Active tasks
└── historylog.md       # Execution history
```

---

## Environment & Configuration

- **Runtime environments:** <dev/staging/prod or equivalent>
- **Required env vars:** <list key vars, secrets, defaults>
- **Local setup:** <basic setup steps or pointer to docs>

---

## Verification

- **Build:** <command>
- **Tests:** <command>
- **Lint/typecheck:** <command>
