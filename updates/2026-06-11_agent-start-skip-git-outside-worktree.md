# Recommendation: Skip Git Status Outside Worktrees

Date: 2026-06-11

## Observed Problem

During `gi обновить` in a consuming project that is not a git repository,
`tools/agent-start.ps1` printed `git status` and `git diff` fatal/usage output.
The update itself succeeded, but startup restore became noisy and harder to
scan.

## Suggested Rule Or Change

Update `agent-start.template.ps1` so it checks `git rev-parse
--is-inside-work-tree` before running `git status --short` or `git diff --stat`.
When outside a git worktree, print one compact line such as `Not a git
repository; skipping git status and diff.`

## Evidence

Project: `D:\AI\Philosophy`

Affected file patched locally: `tools/agent-start.ps1`

## Privacy Review

No secrets, private data, logs, or project product details are included.
