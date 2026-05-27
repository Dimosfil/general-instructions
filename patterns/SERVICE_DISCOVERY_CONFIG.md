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
5. Query `GET /services/{serviceId}` for the named target service.
6. Verify `endpoints.availability` and the expected identity.
7. Query `endpoints.contract` when the task needs the target service protocol,
   schemas, supported actions, or workflow-specific rules.
8. Use `endpoints.api` as the target service API entry point after reading the
   contract.
9. Check required workflow capabilities before using a service.
10. Stop with a clear `service mismatch` blocker when identity, contract, or
   required capabilities do not match.

## Config Service URL Command

Use `gi config service url=<url>`, `ги конфиг сервис url=<url>`, or
`ги конфиг сервис урл=<url>` to declare the canonical config-service URL for
the current environment.

Default:

```text
gi config service url=http://127.0.0.1:4100
```

When this command is used in the shared instruction library, update
`config/gi-main.json` so future agents and local services read the same
`configServiceUrl`. When it is used inside a project with an explicit
project-local override, update only that documented override.

All local services that publish discovery records should read this URL before
registering themselves. Do not hardcode another config-service address in
service startup scripts, task-manager config, summaries, or agent memory.

Validate the URL before saving it:

- It must be a full `http://` or `https://` URL.
- It must not include secrets, tokens, usernames, passwords, query strings, or
  fragments.
- After saving, verify `GET <url>/health` when the task allows contacting the
  running service.

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

Service records are discovery records, not full API documentation. They should
store a service id, display name, `baseUrl`, and the three entry point paths:
`availability`, `contract`, and `api`. Read responses should include full
`endpoints.availability`, `endpoints.contract`, and `endpoints.api` URLs.

Do not store endpoint catalogs, schemas, authentication details, workflow logic,
or secrets in config-service. After discovery, ask the target service for its
contract through `endpoints.contract`.

## Task Managers

Project task-manager config should store the selected manager name or service id
only, plus non-secret project preferences such as workspace, project, and intake
mode. Do not store or copy task-manager runtime URLs in project memory when the
manager is registered in config-service.

For `gi manager`, `gi tm`, `gi manager test`, `gi plan`, and sprint workflows:

1. Read the enabled manager id from project-local task-manager config.
2. Resolve that id through config-service with `GET /services/{serviceId}`.
3. Read `endpoints.contract` to learn the current task-manager API.
4. Use `endpoints.api` for manager operations.
5. Report a concise blocker if the manager id is missing or config-service has
   no matching service record.

## Project-Local Overrides

Use project-local overrides only for explicit project needs, such as selecting a
non-default config service during local development. Keep those overrides small
and documented in project-local instructions.

Do not put secrets, API tokens, cookies, passwords, or private production data
in registry JSON.
