# GI Config Service Plan

## Goal

Create a local discovery/config service so agents in any project can find
current service URLs, endpoints, capabilities, and startup hints without
scanning other project folders or guessing ports.

Stable service URL:

```text
http://127.0.0.1:4100
```

## Core Rule

Projects must not inspect sibling project folders to discover services.

Agent flow:

1. Read project-local overrides only if present.
2. Read GI main config from `D:\AI\general-instructions\config\gi-main.json`.
3. Get `configServiceUrl`.
4. Query GI config service.
5. Verify target service `/health` and required capabilities.
6. Stop with `service mismatch` if identity or required endpoints do not match.

## GI Main Config

Create in `general-instructions`:

```json
{
  "version": 1,
  "configServiceUrl": "http://127.0.0.1:4100"
}
```

This file should contain only bootstrap pointers, not all service data.

## Config Service Responsibilities

The service stores concrete local runtime info for all agent-facing services:

- current `baseUrl`
- health endpoint
- contract/discovery endpoint
- capabilities
- startup hints
- service identity
- API version if known
- notes about UI vs API URLs

It must not store secrets, API tokens, cookies, passwords, or private production
data.

## Suggested API

```text
GET /health
GET /services
GET /services/{serviceId}
GET /services/{serviceId}/startup
GET /projects/{projectId}/services
```

Optional later:

```text
POST /services/{serviceId}/refresh
POST /services/{serviceId}/verify
```

## Example Service Registry Response

```json
{
  "version": 1,
  "services": {
    "worknest": {
      "id": "worknest",
      "name": "WorkNest Task Manager",
      "baseUrl": "http://127.0.0.1:5175",
      "kind": "task-manager",
      "health": "/health",
      "contract": "/agent-intake/contract",
      "capabilities": [
        "task-intake",
        "plan-intake",
        "next-task",
        "task-completion"
      ],
      "startup": {
        "cwd": "D:/AI/worknest",
        "command": "npm run dev:api"
      },
      "notes": "Use API URL, not UI dev server URL."
    },
    "token-lens": {
      "id": "token-lens",
      "name": "Token Lens",
      "baseUrl": "http://127.0.0.1:5220",
      "kind": "analysis-service",
      "health": "/health",
      "capabilities": [
        "token-estimate"
      ],
      "startup": {
        "cwd": "D:/AI/token-lens",
        "command": "npm run dev"
      }
    }
  }
}
```

## Verification Contract

Each registered service should be verifiable by:

1. Requesting its `baseUrl + health`.
2. Confirming returned service identity, for example `service=worknest-api`.
3. Requesting contract/discovery endpoint when available.
4. Checking required workflow capabilities before use.

For example, `gi start sprint` requires:

```text
active sprint lookup
next task lookup
task completion
final status/readback
```

If only `/health` works but lifecycle endpoints are missing, the agent must stop
and report endpoint mismatch.

## Storage

Initial implementation can use a committed example plus user-local config:

```text
config/services.example.json
config/services.local.json
```

`services.local.json` should be gitignored if it contains machine-specific paths
or ports.

## Secrets Policy

Do not store secrets in registry JSON.

Use one of:

- `.env` excluded from git
- Windows Credential Manager
- 1Password / Bitwarden
- explicit user-provided runtime env vars

## General Instructions Changes Later

After the service exists, update `D:\AI\general-instructions` with:

- `config/gi-main.json`
- service discovery pattern
- agent startup rule
- mismatch handling rule
- template for project-local overrides
- warning that agents must not scan sibling project folders for service configs
