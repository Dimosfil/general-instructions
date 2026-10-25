# Unity MCP workspace routing contract

## Scenario and responsibility

Opening a host session selects a working directory. Codex's global
`mcp_servers.unity` configuration owns process launch; the router owns only
workspace detection and backend lifetime. The official Unity MCP owns tool
discovery, protocol handling in Unity sessions, and Editor access.

Mapping: session working directory -> global stdio command ->
`tools/unity-mcp-router.mjs` -> official `unity mcp --project-path <detected root>`
-> protocol and process tests in `tests/test_unity_mcp_router.mjs`.

## Provisioning ownership and workflow

Mapping: GI initialization -> `tools/install-instruction-kit.ps1` -> local
policy/helper/router/probe delivery -> `tools/ensure-unity-mcp.ps1` -> official
dependency installers, Codex MCP configuration commands, and active-project
Pipeline installation -> `tests/test_unity_mcp_setup.mjs`.

Accepted migration `2026.10.17.2__automate_unity_mcp_setup` owns delivery into
existing kits. `tools/get-gi-context.ps1` owns invoking the installed helper on
Unity `start`/`update`; module 20 owns first-task invocation by an agent. Host
setup is separate from the migration fast path so a project transferred to
another machine configures that host even at equal instruction versions.

Portable defaults and official source URLs belong in `config/unity-mcp.json`.
Machine paths are discovered at the I/O boundary and remain in host config.
No source repository runtime dependency or project-local MCP config is added.
The client owns TOML writes through `codex mcp get/add`; the provisioner does
not implement a separate TOML parser or rewrite unrelated client settings.

Only Unity roots enter setup. Bootstrap/accepted-update authorization covers
the bounded host config/user tools and official active-project Pipeline
installation described in module 20 and the private-scope exception. Other
user-home sources, credentials, and projects remain out of scope. Disabled
project/setup policy or client entry is an opt-out; custom Unity servers are
conflicts. Use existing tools before installing missing dependencies; never
upgrade a present Pipeline package or reinstall because an Editor is closed.

After host configuration is verified, install missing Pipeline in the selected
supported Unity project, preserving other dependencies. Installation failure
does not undo completed independent host setup. Return the failed operation
without exposing raw config, credential descriptors, or subprocess stderr.
Do not open an Editor, switch scenes, or launch interactive login. Subsequent
sessions can retry after a blocker changes. Instruction delivery checkpoints
and host/package/live/chat states are separate; report outstanding host state.

The standalone `verify-unity-mcp.mjs` probe performs initialize and tools/list,
has a deadline, and closes its input so the router can terminate its backend.
It does not execute Editor tools, prove project/scene identity, or prove chat
availability. Those remain mandatory agent-side read-only verification before
Editor operations under module 20. Never promote an installed package or
nonempty catalog into a verified live connection.

## Invariants

- Activate only when the selected directory or an ancestor has both Unity
  markers, before crossing an independent Git repository boundary.
- Treat roots, subdirectories, spaces, Unicode, and Git worktrees consistently.
- Never scan descendants/siblings or attach to a globally selected Editor.
- Never persist the detected project in global settings. The router writes no
  project files; only the setup helper may authorize official package changes.
- Pass the detected root as one argument and use it as the backend cwd.
- Use the configured executable without a shell; preserve stdio and exit errors.
- Close backend input on client EOF and stop a backend that fails to exit.
- Outside Unity start no backend, make no network calls, expose no tools, and
  ignore notifications without replying. Reject unavailable methods.

## Client limitation and bypass scope

Official Codex configuration documents `enabled` as a boolean, with
project-local overrides, and no automatic marker-based global enable rule.
The router therefore remains a small empty-catalog MCP endpoint in non-Unity
sessions. It does not promise zero processes or an absent MCP settings entry.
Replace this compatibility mechanism if the client adds native conditional
startup with equivalent workspace identity and isolation guarantees.

At runtime the router needs no instruction hook, watcher, scheduled task,
per-project MCP configuration, or shared-library dependency. Install a copy
into host-local tooling; machine paths belong only in the host config.

## Verification and limits

`node --test tests/test_unity_mcp_router.mjs` covers non-Unity initialization and
empty discovery with an executable that must not be started, marker detection,
repository boundaries, transparent initialize/list/call forwarding through a
fixture backend, exact project arguments, and startup failure behavior.
It also checks that unavailable tools are rejected outside Unity and an
unresponsive backend is terminated when the client closes stdin.

`tests/test_unity_mcp_setup.mjs` exercises the real Codex MCP config writer in
isolated client homes, with an offline Unity CLI fixture. It covers fresh
bootstrap and second-host/zero-pending-update setup, idempotency, unrelated
config/comments/packages, opt-outs/custom conflicts, Pipeline failure with
independent host success, a rejected runtime checksum, and protocol discovery
reported separately from live Editor/chat state. Dependency downloads and Unix
installation branches require live platform checks; they are not proven by the
offline fixtures. Windows is the platform used for these regression checks.

An ephemeral Codex app-server probe on 2026-10-17 independently selected
ordinary and Unity fixture workspaces with different working directories from
the server itself. `mcpServerStatus/list` returned no tools for the ordinary
workspace and the fixture's read-only tool for the Unity workspace.
`mcpServer/tool/call` confirmed the detected Unity root as the backend cwd and
its explicit project selector. This verifies Codex's workspace propagation and
tool discovery through the installed router, using a fixture rather than an
Editor. Unrelated MCPs were disabled only in that probe's process overrides.

Live verification on 2026-10-17: `unity --json --no-banner status` returned
`STATUS_NO_INSTANCES`; no Pipeline-enabled Editor was discoverable. Therefore
live project/scene identity and tools in this chat remain unverified. Do not
interpret fixture success as a live Editor connection. The configured global
entry takes effect in newly loaded client sessions; project-level overrides
and missing Pipeline packages can still prevent tool availability.

User-facing installation and limitations: [router documentation](../../../../docs/unity-mcp-router.md).
