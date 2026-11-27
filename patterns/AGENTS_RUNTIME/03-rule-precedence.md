## Rule Precedence

- Treat safety, secrets, and destructive-action constraints as highest priority.
- Follow explicit user requests within higher-priority instructions and safety
  constraints. Treat shared rules and skills as defaults where the user has
  explicitly authorized a different task-scoped behavior.
- Treat explicit user wording such as "do by GI", "follow GI", "strictly by
  GI", and equivalent local-language forms as a request for strict compliance
  with all loaded GI rules. These rules are mandatory execution constraints
  unless the current user message explicitly overrides a specific rule for the
  current task.
- If an applicable GI rule cannot be followed, stop the affected operation and
  report the concrete blocker or explicit deferral. Continue independent,
  authorized work; do not claim full completion while a required step is blocked.
- Let project-local `AGENTS.md`, runbooks, and working agreements override these
  shared reusable rules when they are more specific.
- Use these shared rules when project-local guidance is absent or ambiguous.
- Agents may ask concise clarification questions about implementation details
  and may propose a better-fit solution, workflow, stack, algorithm, or tradeoff
  when it improves the user's stated goal.
- Prefer token economy and optimization after the correct scope is clear.

## Windows Git And Focus

- On Windows, automated Git must never open a window or steal keyboard focus.
  This includes read-only commands and indirect launches by tests, hooks,
  scripts, and tools. Verify the actual launch path before running it. If it
  cannot be kept windowless, stop that operation and report the blocker.
  Follow `05-windows-command-policy.md` for the launch requirements.

## Computer Use

- Keep desktop Computer Use off by default. Obtain explicit user permission
  before the first action that inspects or controls the user's desktop, native
  apps, or windows. This covers read-only inspection, screenshots, window or
  app discovery, and equivalent desktop automation through scripts or tools.
- Start with a suitable API, CLI, connector, non-UI test, headless browser, or
  built-in browser. Use browser-only operations in the built-in browser within
  the authorized task without separate Computer Use permission. Apply this
  distinction to the operation even when tools share an interface.
- If a step needs desktop Computer Use, explain why, name the target app and
  intended actions, and ask before acting. While waiting or after a refusal,
  continue independent work through available alternatives and report any step
  that remains unverified. Silence does not grant permission.
- Explicit permission lets the agent choose Computer Use. A direct instruction
  to use it selects that method for the agreed scope. By default, permission
  covers only the current task and agreed actions. Ask again before expanding
  that scope. Use available alternatives for general UI test requests. Tool
  availability, local instructions, and skill guidance do not grant permission.

## Authorization And Follow-Through

- Treat requests to do, fix, review, or help with a task as instructions to
  carry it through to the requested result, not merely to offer a plan.
- Reuse authorization and preferences already established in this session for
  the same action, target, and scope. Ask again only when a material change or
  an explicit approval requirement makes that authorization insufficient.
- Resolve routine, reversible implementation choices from current context.
  Ask focused questions when missing information materially affects correctness,
  scope, external effects, cost, or data safety. Continue work that does not
  depend on the answer; silence is not approval.
- Before required approval, prepare the authorized, reviewable work. Hold only
  the operation requiring approval and its dependent steps. Preserve explicit
  controls for destructive actions, external sends, secrets, and external paths.
- If an instruction or skill requires a pause, identify the exact file and
  rule, explain its applicability and what remains blocked. Do not invent an
  approval gate from a general recommendation or hypothetical risk.

## Simplicity And Material Complexity

- Prefer the simplest complete solution; avoid speculative features/abstractions.
- Before unapproved material complexity (new infrastructure/storage, stack
  changes, broad restructuring, public-contract expansion, or substantial
  dependencies), explain need, simpler alternatives, and impact; obtain explicit
  agreement before implementation. Do not build the expansion to seek approval.
- Reuse existing agreement. Routine reversible work needs no approval or new
  paperwork; continue independent steps. Silence is not agreement.

## Code-Change Gate

- Fix the cause at the contract owner. Document bypasses and get approval
  when they change an agreed contract.
- Keep changeable policy in its authoritative contract. Use its documented
  behavior for missing or invalid data. Before completion, check those cases
  when relevant and reject silent hard-coded fallbacks.

## Whole-Task Completion Gate

- For full-scope work, inventory all agreed areas before edits. Keep one list
  of areas checked, findings, and blockers. Continue through it without a
  reminder. Claim completion only after all areas are checked and each finding
  is resolved or explicitly accepted.
- Check actual results against every requirement. Verify through the actual
  components. Distinguish implemented, executed, and verified work. Report
  unresolved and unverified requirements, blockers, and impact.
- Use the smallest sufficient checks. Heavy or full suites, whole-catalog audits,
  and large test matrices need an explicit request, documented project requirement,
  or prior agreement. `gi start` alone authorizes none of these.
- This gate applies even with optional final review off. Reuse evidence.
  Git finalization does not reopen verified product work.

## Database Raw Output

- For DB `raw` / `рау`, load `patterns/AGENTS_RUNTIME/07-scope-and-evidence.md`.
  Default: horizontal Markdown table (columns across, records down); JSON only
  on explicit request, never just because a tool returns JSON.

## Final Response

- Complete required checks and the enabled final review internally before
  sending one final response. Do not send a provisional final followed by a
  routine reviewed copy or expose successful internal review reminders.
- Use plain text or Markdown, without raw HTML tags. Summarize large file
  inventories by count, directory and reason; name individual paths only when
  requested or needed to explain a specific change or blocker. Keep every
  selected file accounted for internally and report all material gaps.
