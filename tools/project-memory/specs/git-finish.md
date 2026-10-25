# Git Finish Contract

Status: current accepted instruction behavior.
Last checked: 2026-10-25.

## Ownership And Evidence

GI Git finish is an agent workflow, not a shell command or an autonomous Git
executor. The resolver supplies instructions; the agent performs Git operations.

- Runtime contract: `patterns/AGENTS_RUNTIME/16-git-policy.md`.
- Detailed workflow: `patterns/GIT_WORKFLOW.md`.
- Routing: `config/gi-command-routes.json`, `tools/resolve-gi-command.ps1`, and
  `tools/get-gi-context.ps1`.
- Consumer agreements: `templates/AGENT_WORKING_AGREEMENTS.template.md`.
- Verification: routing and bootstrap regression scripts under `tools/`.

## Selection And Delivery

1. Verify the current repository, branch, upstream, and full command. Preserve
   command modifiers in the context packet's `Requested command` line.
2. For commit commands, use explicit selection first, then an actual active
   conversation task, otherwise all eligible current repository changes. Missing
   chat history requires no scope confirmation. Old summaries alone are not an
   active task.
3. Explicit `all`, `всё`, or `все` selects eligible staged, unstaged, untracked,
   deleted, and pre-existing changes across the current repository, overriding
   the task default. Concrete separate-work reservations remain exclusions or
   scope conflicts. Do not include ignored files, other repositories, worktrees,
   or branches; do not infer force-push authorization.
4. Inventory individual paths, inspect changes and existing staged contents,
   exclude secrets, prohibited payloads, and generated output, and reconcile the
   staged diff against every eligible selected change before commit. Preserve
   the user's index; an inseparable or conflicting exclusion is a blocker.
5. Commit selected changes when present. Commit/push commands still deliver
   existing outgoing commits after compact Git safety checks when no new commit
   is needed. Never create an empty commit or request a second push-only command.
   No pending commit or push means the branch is current, not a failed command.
6. Verify final status with individual untracked paths and upstream equality.
   Report each remaining changed path with its exclusion reason or blocker;
   eligible selected residue means incomplete work. Upstream equality alone does
   not establish completion or a clean worktree.

## Decision Cases

| Request and state | Required result |
| --- | --- |
| Ordinary push in a new chat | All eligible current repository changes are selected. |
| Ordinary push during a task | Task changes selected; unrelated dirt reported separately. |
| Push all during a task | All eligible repository changes selected, including pre-existing edits. |
| Explicit paths | Only those eligible changes selected. |
| Selected deletion or new file in a directory | Included in inventory and staged reconciliation. |
| No new changes, outgoing commits | Inspect and push commits without creating an empty commit. |
| No new changes or outgoing commits | Report current branch state. |
| Only push, including an all modifier | Never stage or commit working-tree files. |
| Push-only needs a merge commit | Stop: push-only permits fast-forward integration, not new commits. |
| Excluded path or separately reserved work | Explain exclusion or concrete conflict; do not silently omit. |
| Expected ignored file | Explain matching ignore rule; do not force-add. |
| Eligible selected residue after commit | Finish remains incomplete even if upstream matches. |
| Missing upstream, Git conflict, or failed push | Report the specific blocker; no force-push or unrelated repair. |
| Upstream has new commits | Fetch and pull/merge before push, preserving both histories; no PR required by GI. |
| Divergent committed histories | Create a normal merge; stop on conflicts or obstructing local changes. |
| Force-with-lease, mirror, forced refspec or API replacement of main history | Forbidden, including deletion/recreation; a lease is not an exception. |

## Published History Contract

Scenario: a sync or repair would replace the remote main-branch history.
Mechanism: Git finish is routed to runtime module 16; the agent fetches the
actual destination, integrates incoming commits with a fast-forward or normal
merge, verifies ancestry and performs only a normal push. A push request
authorizes this synchronization without imposing a pull request. Project-local
PR requirements still apply. Ownership: `16-git-policy.md` and the Git workflow, mirrored in
consumer working agreements. Invariant: published commits on `master`, `main`
and the default branch remain ancestors of the new tip, together with local
commits. Conflicts, obstructing dirty files, failed fetch or uncertain target
block integration/push. Never discard either history, auto-stash unrelated work
or force a rejected push. New incoming commits may be safely integrated after
fresh inspection; other rejection causes remain blockers. Explicit no-rebase
pull or fetch/merge avoids config-selected history rewriting. Push-only retains
its no-new-commits contract and cannot create a divergent-history merge commit.

Verification: inspect delivered Git-finish context, run routing/bootstrap and
release-order checks, and inspect migration delivery. These checks validate
instruction availability, not host enforcement. Inspect effective host settings
separately; changing them requires an explicit repository protection request.

## Propagation And Verification Limits

Migration `2026.10.13.1__complete_git_push_selection_and_delivery` updates live
rules, resolver, command index, and consumer agreements. Fresh bootstrap also
copies the referenced Git workflow. Routing regressions check modifier retention,
alias precedence, contract availability, and budgets; bootstrap regressions
check copied contracts across source forms. These checks validate the instruction
kit, not model compliance in every future chat or a consumer's product state.
