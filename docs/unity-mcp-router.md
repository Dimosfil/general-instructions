# Automatic Unity MCP routing

## GI lifecycle

GI bootstrap copies the setup policy, provisioner, router, and protocol probe
into the target kit, then runs `tools/ensure-unity-mcp.ps1`. Accepted migration
`2026.10.17.2__automate_unity_mcp_setup` delivers the same mechanism to existing
projects. `gi start` and `gi update` run it for Unity roots even when no file
migrations are pending. On the first ordinary task in a Unity session, the
agent follows runtime module 20 and reuses any setup result already produced.
Thus a project copied to a new PC can provision that PC without new instructions.

The provisioner detects Codex home from `CODEX_HOME` or the current user's
`.codex` folder, discovers local executables, and checks CLI help. Missing Node
is downloaded from the official distribution with SHA-256 validation; missing
Unity CLI uses its official Windows or macOS/Linux installer. Runtime and CLI
copies go into dedicated user tooling. Other clients are reported as an
unsupported setup target instead of installing Codex for them. PowerShell and
Codex CLI must already be available to run this GI setup.

The provisioner copies the router and probe into stable user tools and uses
`codex mcp get/add` to configure the global client. No source checkout remains
a runtime dependency. Repeated setup preserves matching files/settings. Custom
Unity entries are reported as conflicts; unrelated MCP entries, comments, and
settings survive. Explicitly disabled existing entries are preserved.

In the active Unity project, it installs missing `com.unity.pipeline` through
`unity pipeline install --project-path <root> --non-interactive --json` after
checking help. It preserves existing Pipeline versions and unrelated packages.
Pipeline currently requires Unity 6 or newer. This authorized package change
may cause an open Editor to recompile. It never opens/closes an Editor, changes
scenes, enters Play Mode, upgrades Pipeline, or initiates interactive login.

Configure portable policy and official source URLs in `config/unity-mcp.json`.
Set `enabled` to false there, or `unity_mcp.enabled` to false in
`tools/project-memory/instruction-kit.json`, to opt out of automatic setup.
Absent policy defaults to enabled for Unity roots. Ordinary projects return
before user-home reads, dependency checks/downloads, or backend launches.

Inspect setup without applying changes (the protocol check still starts a
temporary backend):

```powershell
.\tools\ensure-unity-mcp.ps1 -ProjectPath <active-project-root> -CheckOnly
```

Use `-SkipLiveCheck` for configuration/package inspection only. Results separate
configuration, Pipeline, stdio initialization/tool discovery, and current-chat
verification. Login/network failures, missing prerequisites, unsupported hosts,
and custom-config conflicts are named blockers. A closed/importing Editor can
leave live verification pending while configuration remains installed. The
next session retries setup; no repeated login/network loop runs in one call.

## Host configuration

Install `tools/unity-mcp-router.mjs` once into a stable user-owned tooling
directory. Configure the host's global Unity MCP entry to run Node with that
file, followed by the installed official Unity executable and `mcp`:

```toml
[mcp_servers.unity]
command = "<absolute path to node executable>"
args = ["<absolute path to unity-mcp-router.mjs>", "<absolute path to unity executable>", "mcp"]
enabled = true
startup_timeout_sec = 30
```

Replace the placeholder paths with the host's installed paths. Leave `cwd`
unset so Codex passes the selected session's working directory. Do not add a
fixed `--project-path`: the router supplies it separately for each session.
Keep the installed file synchronized when updating its source.

The router checks the working directory and its ancestors for both an `Assets`
directory and `ProjectSettings/ProjectVersion.txt`. It stops at the nearest Git
repository boundary, including a worktree `.git` file. It never searches sibling
projects or chooses an arbitrary open Editor. A workspace containing several
Unity projects must select a specific project's directory.

In a Unity workspace the router starts the official `unity mcp` with that
project's explicit `--project-path` and forwards its stdio unchanged. Backend
startup failures remain visible. No client files are written into projects;
new projects use the same global configuration automatically.

Outside Unity, a small Node routing process responds to MCP initialization and
returns an empty tool catalog. It does **not** launch the Unity CLI/backend,
query Editors, poll, access the network, or install packages. The server entry
may still appear in the client's MCP settings. This is an explicit compromise:
Codex supports a boolean `enabled` and project configuration files, but does
not document a global file-presence condition for server startup.

Unity CLI installation, client routing, and the project's Pipeline package
remain separate. Live Editor tools need an open Editor with Pipeline ready.
The router itself only gates backend startup; the GI provisioner handles
installation. Neither refreshes a chat's already-loaded tools.
Start a new chat in the selected Unity project after changing global settings;
restart the client if it retains its old MCP configuration. A project-local
override disabling `unity` still takes precedence over the global setting.

Verify routing without starting Unity:

```powershell
node <absolute-path-to-router> --check
```

Run the regression checks from this repository:

```powershell
node --test tests/test_unity_mcp_router.mjs
node --test tests/test_unity_mcp_setup.mjs
```

For a live connection require `initialize`, nonempty `tools/list`, and a
read-only tool call confirming the intended project's Editor/scene state.
Separately call the tools exposed in the actual chat. Configuration and a
standalone probe do not prove that the current chat loaded Unity tools.

See the [integration contract](../tools/project-memory/specs/integration-contracts/unity-mcp-routing.md)
and [official Codex MCP configuration](https://developers.openai.com/codex/mcp).
Dependency contracts: [Unity CLI installation](https://docs.unity.com/en-us/unity-cli/use-unity-cli),
[Unity Pipeline](https://docs.unity.com/en-us/unity-cli/unity-pipeline/unity-pipeline-package),
and [Node.js distributions](https://nodejs.org/en/download).
