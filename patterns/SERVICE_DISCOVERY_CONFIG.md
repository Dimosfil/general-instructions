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

Only web-facing applications should use startup self-registration: HTTP APIs,
web apps, task-manager services, local daemons with a port, or other services
that expose a runtime URL another project may need to discover. Desktop apps,
CLI tools, libraries, scripts, and other non-web applications must not query or
publish to config-service during normal startup unless project-local
instructions explicitly say they expose a discoverable local service.

Web-facing applications must check the current config-service config on every
process startup before publishing or refreshing their own service record. During
startup, query the app's own configured `service_id`; if the service record is
missing, create it with the current port and documented endpoints. If the record
exists but the port or endpoints changed, refresh it. Treat cached or previously
bundled config as a fallback only after a live check fails and the local run
instructions explicitly allow degraded startup.

Validate the URL before saving it:

- It must be a full `http://` or `https://` URL.
- It must not include secrets, tokens, usernames, passwords, query strings, or
  fragments.
- After saving, verify `GET <url>/health` when the task allows contacting the
  running service.

## App Self-Registration Flag

Use `gi config service on`, `gi config service off`, `ги конфиг сервис on`, or
`ги конфиг сервис off` to set whether the current application should publish
itself to config-service during startup.

- `on` means a web-facing application is expected to self-register or refresh
  its own config-service record on startup.
- `off` means the application must not publish or refresh its own service
  record, even if config-service is available.
- For non-web applications, leave this flag off or absent unless local run
  instructions define a web/API runtime for the project.
- Store this flag alongside the project's documented config-service URL or run
  instructions. Do not store the flag in GI main config, and do not reinterpret
  it as starting or stopping the config-service process.
- When setting the flag to `on`, first confirm a config-service URL is already
  configured in that same local config path or in the documented GI bootstrap
  config. If no URL is configured, stop and tell the user to set
  `gi config service url=<url>` before enabling self-registration.
- If the project has no documented place for this flag, ask one short
  clarification question instead of inventing a hidden config file.

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

## FTP Services

Projects that need FTP, FTPS, or SFTP should resolve shared FTP services through
config-service before asking the user for host details or creating a purely
project-local deploy config.

Use `gi ftp service`, `gi ftp сервис`, or `ги фтп сервис` to manually register,
inspect, or select an FTP/FTPS/SFTP service record. This command must not upload
files.

FTP-capable service records should expose non-secret discovery metadata only:
service id, display name, protocol, base URL or host/port when policy allows it,
endpoint paths, capability tags, and secret reference names such as
`passwordEnv`. Do not store raw passwords, tokens, private keys, or private
remote paths in config-service.

When resolving FTP for a project:

1. Read the project-local FTP config and selected `serviceId`, if present.
2. If no `serviceId` is selected, query config-service for FTP-capable services.
3. If exactly one matching service exists, read and verify its contract, then
   use it.
4. If several matching services exist, ask the user to choose with the numbered
   Markdown checkbox style used by language selection, such as
   `- [ ] 1. Display name (service-id)`, and accept numeric replies against the
   latest checklist.
5. If no matching service exists, offer `gi ftp service` as the command to
   register one manually, then fall back to project-local FTP config only when
   the user provides project-specific details.

## Project-Local Overrides

Use project-local overrides only for explicit project needs, such as selecting a
non-default config service during local development. Keep those overrides small
and documented in project-local instructions.

Do not put secrets, API tokens, cookies, passwords, or private production data
in registry JSON.
