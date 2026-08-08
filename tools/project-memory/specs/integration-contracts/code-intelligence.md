# Code Intelligence Federation

Last reviewed: 2026-08-06

## Intent

GI can optionally enrich project-memory retrieval with implementation-level
evidence from a code-intelligence provider. The feature must remain portable,
disabled by default, and useful without making Repowise or any other provider a
hard dependency.

## Authority And Data Flow

1. The question router reads project-local indicators from `rag-system.json`.
2. Project-memory retrieval answers intent, specification, workflow, decision,
   and durable project-fact questions.
3. The code-intelligence adapter answers symbol, call/dependency, change-risk,
   Git-hotspot, and health questions through allowlisted MCP tools.
4. Mixed questions use both sources and keep their evidence distinguishable.
5. Current source files remain the final verification source before an edit.

The provider response is returned intact inside a GI envelope. GI adds provider
identity and freshness facts but does not rewrite provider findings into
durable project decisions automatically.

## Invariants

- `code_intelligence.enabled` defaults to `false`.
- Project memory is usable when the provider is absent, disabled, failing, or
  stale.
- Only local MCP stdio and explicitly allowlisted tools are executable by the
  shared adapter.
- Command arguments are passed without a shell.
- External project paths require an explicit opt-in.
- Generated provider indexes are ignored and are never project-memory content.
- Provider installation, index creation/rebuild, editor integration, and code
  mutation remain outside adapter status/query operations.
- A commit mismatch is stale; a dirty worktree is always surfaced separately.
- Routing vocabulary is configuration data, not hidden application logic.

## Failure Handling

- Invalid or missing enabled configuration fails before starting a subprocess.
- A missing executable, MCP timeout, protocol error, or unavailable allowlisted
  tool produces a bounded error and leaves normal GI retrieval intact.
- Stale results are warned by default and may be rejected by project policy.
- Unreported index commit is stale when `require_indexed_commit` is enabled.
- Secrets are never accepted as inline environment values; configuration names
  environment variables to inherit from the process.

## Current Implementation

- Contract and first provider guidance:
  `patterns/CODE_INTELLIGENCE_ADAPTERS.md`.
- Project configuration: `tools/project-memory/rag-system.json`.
- Stdlib MCP bridge: `tools/project-memory/code_intelligence.py`.
- Static RAG validation: `tools/project-memory/rag_check.py`.
- Regression tests: `tests/test_code_intelligence.py` and its local MCP fixture.
- First evidence provider: Repowise, optional and independently installed.

## Verification

- Unit tests prove routing, allowlist enforcement, MCP initialization/calls, and
  freshness warnings.
- JSON parsing proves the live and template configuration shapes stay valid.
- `rag_check.py` validates the section and ignored generated paths.
- A real-provider check must confirm `status`, `get_context`, and `get_risk`
  against a known repository without writing editor configuration.
