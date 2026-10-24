# Automatic GI Lifecycle

Codex executes `.codex/hooks.json`; the agent does not need to call the hook.
The shared contract owner remains module 03 and `tools/get-gi-context.ps1`.
Hooks deliver that live source instead of maintaining another copy of the rules.

- `UserPromptSubmit` injects the complete mandatory Work rules as developer
  context on each user turn.
- `SessionStart` with source `compact` restores them after context compaction.
- `Stop` independently builds Complete context, runs Git whitespace checks,
  and blocks the first completion attempt to require review of the entire task
  and honest gaps. Manual `-Phase Complete` cannot bypass or satisfy this hook.
  An automatic continuation with unchanged rules, HEAD, index, working changes,
  and nonignored untracked files can then finish. Changes require another review.

State is local and ignored under `.codex/.gi-hook-state/`. It contains hashes,
event names, counts, and check outcomes; no prompt, transcript, response, or
source diff is saved. Missing rules or a failed loader stop visibly as unverified.
Repeated failures or changes stop after three review requests with an explicit
warning, avoiding an infinite loop. No extra forms or routine approvals are added.

## Activation

Use a Git project and PowerShell 7 (`pwsh`) available to the Codex hook host.
Install the kit normally; the installer preserves unrelated handlers and merges
only the canonical GI definitions. It reports **configured**, never active merely
because files were copied. A preserved, different lifecycle script requires a
scoped migration merge.

Codex must support and enable native hooks, trust the project `.codex` layer,
and trust the exact three GI definitions. Review them through `/hooks` in the
running host; changed definitions require trust again. Verify **Active** for
UserPromptSubmit, SessionStart, and Stop. Existing chats may require reopening
after installing hooks. There is no portable repository file that can grant
itself trusted status in every host.

Without active native hooks, the entrypoint's manual helper calls remain a
fallback; they provide no independent enforcement of invocation. Do not describe
that fallback or an untrusted installation as automatic enforcement.

## Verification

Run `tools/test-gi-lifecycle-hooks.ps1` for protocol, compaction, omitted Complete,
changed files, failed checks, missing loader, bounded retries, and privacy.
Run `tools/test-gi-lifecycle-hooks-live.ps1 -FixturePath <empty-test-directory>`
for a real authenticated Codex CLI session in an isolated installed kit. The
first run creates an owned fixture; trust that project and its three hooks
through the native UI, then rerun. The fixture remains available for repeated
checks. It deliberately permits no tools or manual
Complete. Require the initial response, native Stop continuation, final response,
and actual audit sequence: rules injected -> review required -> completion allowed.

The live test inventories all visible hooks, rejects other sources, vets the
installed definitions, and requires normal persisted project and exact hook trust.
It does not bypass trust, modify trust state, or copy credentials. Host activation
is checked through `/hooks` and the app-server `hooks/list` API. Repeat
tests against the published source and its installed kit.

All GI limits and Codex's default hook output threshold remain unchanged. The
entire output is bounded by the existing GI section cap, with no partial rule
packet on overflow. Hooks force delivery and a review opportunity; whitespace
checks do not prove product behavior. Required project tests and end-to-end
evidence still depend on the task. Stop runs after a candidate response may have
streamed, so it forces a continuation rather than retracting that text. Local
hooks are not tamper-proof and cannot guarantee model honesty or correctness.

Official behavior and trust contract: [Codex hooks](https://learn.chatgpt.com/docs/hooks).

Правила загружаются средой Codex, финальная проверка запускается автоматически.
Пропуск `Complete` больше не пропускает проверку в доверенной среде с активными
hooks. Это не гарантия безошибочности: рабочие сценарии всё равно нужно проверять,
а недоделки и границы проверки — честно указывать.
