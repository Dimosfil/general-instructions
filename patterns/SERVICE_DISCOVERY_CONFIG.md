# Service Discovery Config

Use the GI config service for local runtime discovery. Do not scan sibling
project folders, guess ports, or reuse stale task-manager memory as a substitute
for live service discovery.

## Bootstrap Flow

1. Read project-local overrides only when local project instructions explicitly
   define them.
2. Read GI main config from
   `D:\AI\general-instructions\config\gi-main.json`, or from the
   `GENERAL_INSTRUCTIONS_HOME` equivalent.
3. Read `configServiceUrl`.
4. Query the GI config service.
5. Verify the target service `/health` endpoint and expected identity.
6. Query contract or discovery endpoints when available.
7. Check required workflow capabilities before using a service.
8. Stop with a clear `service mismatch` blocker when identity, contract, or
   required capabilities do not match.

## GI Main Config

The GI main config is only a bootstrap pointer:

```json
{
  "version": 1,
  "configServiceUrl": "http://127.0.0.1:4100"
}
```

Do not store all service data in this file.

## Config Service Contract

The config service should expose:

```text
GET /health
GET /services
GET /services/{serviceId}
GET /services/{serviceId}/startup
GET /projects/{projectId}/services
```

The stable local URL is:

```text
http://127.0.0.1:4100
```

## Project-Local Overrides

Use project-local overrides only for explicit project needs, such as selecting a
non-default config service during local development. Keep those overrides small
and documented in project-local instructions.

Do not put secrets, API tokens, cookies, passwords, or private production data
in registry JSON.
