# Automatic GI Lifecycle

For the OpenCode adapter to this same engine, see [OpenCode GI hooks](gi-opencode-hooks.md).

Codex executes `.codex/hooks.json`; the agent does not need to call the hook.
The shared contract owner remains module 03 and `tools/get-gi-context.ps1`.
Hooks deliver that live source instead of maintaining another copy of the rules.

- `UserPromptSubmit` injects the complete mandatory Work rules as developer
  context on each user turn.
- `SessionStart` with source `compact` restores them after context compaction.
- `PreToolUse` automatically prepends mandatory Work rules to the `prompt` of
  Codex `create_thread` and `send_message_to_thread`. Desktop service deliveries
  do not emit `UserPromptSubmit`. This hook runs in the sending chat, before the
  service call; the recipient needs no manual helper call. The rules arrive in
  the delegated service input, not a fabricated developer-role message.
- `Stop` independently builds Complete context and runs Git whitespace checks.
  Passing checks return empty JSON, recording `completion_allowed` locally
  without a chat message or second response. Manual `-Phase Complete` does not
  replace these automatic checks. Only actual check failures request correction.

Work, compaction and service context deliver module 03's requirement to review
the actual result internally before one final response. The enabled module 15
review follows the same timing. Use Markdown without raw HTML; summarize large
file inventories by count, directory and reason, retaining specific blockers.
Successful checks never issue a review reminder. This replaces the former
always-blocking Stop contract: a post-response hook cannot retract a streamed
answer, and Codex turns a blocking `reason` into a new user continuation.
See the official [Stop protocol](https://learn.chatgpt.com/docs/hooks#stop).
GI uses empty JSON on success rather than unsupported output suppression.

State is local and ignored under `.codex/.gi-hook-state/`. It contains hashes,
event/tool names, delivery action, counts, and check outcomes; no prompt, transcript, response, or
source diff is saved. Missing rules or a failed loader stop visibly as unverified.
Repeated failed checks stop after three correction requests with an explicit
warning, avoiding an infinite loop. No extra forms or routine approvals are added.

## Activation

Treat this section and the Codex live tests below as runtime readiness checks.
They do not gate recording verified kit file installation, including installation
from OpenCode. Follow the [startup applicability rules](../patterns/AGENTS_RUNTIME/07-startup.md).
Report unavailable or failed activation separately; zero pending migrations is
not proof of trusted hooks. Use manual Work/Complete until hooks are verified.

Use a Git project and PowerShell 7 (`pwsh`) available to the Codex hook host.
Install the kit normally; the installer preserves unrelated handlers and merges
only the canonical GI definitions. It reports **configured**, never active merely
because files were copied. A preserved, different lifecycle script requires a
scoped migration merge.

Codex must support and enable native hooks, trust the project `.codex` layer,
and trust the exact four GI definitions. Review them through `/hooks` in the
running host; changed definitions require trust again. Verify **Active** for
PreToolUse, UserPromptSubmit, SessionStart, and Stop. Open or reload the sending
chat after adding the service hook: an already-running turn can retain its old
hook configuration. There is no portable repository file that can grant
itself trusted status in every host.

Without active native hooks, the entrypoint's manual helper calls remain a
fallback; they provide no independent enforcement of invocation. Do not describe
that fallback or an untrusted installation as automatic enforcement.

## Verification

Run `tools/test-gi-lifecycle-hooks.ps1` for protocol, compaction, omitted Complete,
quiet success, service delivery, unchanged task/destination, UTF-8, prefix reuse,
unavailable-rule denial, staged/unstaged failure, repair, bounded retries and privacy.
Run `tools/test-gi-lifecycle-hooks-live.ps1 -FixturePath <empty-test-directory>`
for a real authenticated Codex CLI session in an isolated installed kit. The
first run creates an owned fixture; trust that project and its four hooks
through the native UI, then rerun. The fixture remains available for repeated
checks. It deliberately permits no tools or manual
Complete. Require exactly one final response, no routine Stop continuation,
current pre-response rules and the audit sequence: rules injected -> completion
allowed. This proves context delivery and automated checks, not semantic review.

The live test inventories all visible hooks, rejects other sources, vets the
installed definitions, and requires normal persisted project and exact hook trust.
It does not bypass trust, modify trust state, or copy credentials. Host activation
is checked through `/hooks` and the app-server `hooks/list` API. Repeat
tests against the published source and its installed kit.

For Desktop service verification, use a freshly loaded sender with the four
trusted hooks. Create one recipient through the native tool, then send it a
second service message. The sender must pass only the original test prompts,
without manually adding rules or calling the helper. The recipient must use no
tools or manual Work/Complete. Read both actual service inputs: require the
generated prefix, the complete current module 03, unchanged task text, and
one final response without a routine native hookPrompt. Correlate both tool calls
with sender
audit entries `PreToolUse/service_rules_forwarded/delivery=added` and both
recipient turns with `completion_allowed`, without a review continuation.
Do not substitute a typed user message or a CLI run for either service path.

The hook uses `get-gi-context.ps1 -Phase Work -MandatoryOnly`: it forwards shared
mandatory policy without sender update status, project preferences, or local
runtime data. Preserve every destination/model/routing field and the exact
original prompt suffix. Reuse an identical generated prefix without duplication;
never strip arbitrary user text. Deny the service call explicitly if rules or
the loader are unavailable or the prefix exceeds the existing section cap.
Permission checks and authorization requirements still apply to the actual call.

All GI limits and Codex's default hook output threshold remain unchanged. The
entire output is bounded by the existing GI section cap, with no partial rule
packet on overflow. Hooks force rule delivery and automated completion checks;
they do not independently prove that the agent performed semantic review.
Required project tests and integrated evidence still depend on the task. Stop
runs after a response may have streamed. A real failure can therefore create a
visible correction, but success must not create a continuation. Missing context
and retry exhaustion remain visible failures. Local hooks are not tamper-proof.

Official behavior and trust contract: [Codex hooks](https://learn.chatgpt.com/docs/hooks).

Правила загружаются средой Codex; автоматические проверки завершения выполняются
даже без ручного `Complete`. Содержательная проверка — обязанность агента до
единственного итогового ответа. Успешный Stop не создаёт сообщения в чате.
Реальные ошибки проверки остаются видимыми; недоделки и границы проверки нужно
честно указывать. Hook не доказывает правильность содержательного анализа.
Служебные сообщения между чатами получают общий обязательный блок автоматически
через hook отправителя; его локальные настройки получателю не передаются.
