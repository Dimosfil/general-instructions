# Agent Recommended General Instructions Updates

Date: 2026-05-15
Target repository: `D:\AI\general-instructions`
Audience: future AI agents maintaining the reusable instruction library

## Summary

Collected feedback says the instruction library is strong in substance:
safe defaults, reusable scope, token-conscious retrieval, explicit bootstrap
behavior, review-before-commit git policy, and `updates/` as intake.

The main improvement area is structure. `AGENTS.md` and
`GENERAL_DEVELOPMENT_PLAYBOOK.md` contain duplicated or overly broad rules, and
some situational startup/bootstrap guidance is always loaded even though it only
applies in narrow cases.

## Key Conclusions

- Preserve the current philosophy: small context, targeted retrieval, no
  secrets, no project-specific rules in the shared library, and user review
  before commits.
- Reduce duplication in always-loaded instructions, especially repeated rules
  about not reading large files in full.
- Split broad flat rule lists into shorter grouped sections.
- Move narrow startup behavior into patterns where possible.
- Make shell-specific command examples explicitly PowerShell examples, with
  equivalent commands expected on other shells.
- Clarify rule precedence and scope expansion behavior.

## Recommended Tasks

### 1. Deduplicate `AGENTS.md`

- Merge repeated "do not read large files in full" guidance into one bullet.
- Keep examples such as `Get-Content -TotalCount`, `Get-Content -Tail`, and
  targeted searches in that single rule.

### 2. Regroup `AGENTS.md`

Replace the long flat `Editing Rules` list with short subsections, such as:

- Content and authoring
- Tool usage and token economy
- Startup behavior
- UI and focus
- Update intake
- Verification and git

### 3. Move Situational Startup Guidance Into A Pattern

- Add `patterns/FIRST_MESSAGE_HANDLING.md`.
- Move or summarize rules about first-message-as-title and shared-instruction
  bootstrap path handling there.
- Keep only a short pointer in `AGENTS.md` if the rule must stay visible.

### 4. Clarify Shell Assumptions

- Add a note that command examples use PowerShell on Windows.
- Say agents should use equivalent head, tail, line-range, and targeted-search
  commands on other shells.

### 5. Clarify `updates/`

- Separate guidance for maintaining this repository from guidance for external
  projects that discover reusable improvements.
- Remove overlapping `updates/` paragraphs where possible.

### 6. Add Rule Precedence

Suggested precedence:

1. Safety, secrets, and destructive-action constraints.
2. Explicit user request.
3. Project-local `AGENTS.md` or runbook.
4. Shared reusable instructions.
5. Optimization and token economy preferences.

### 7. Generalize Broad Artifact Guidance

- Replace the specific zip-archive rule with a broader rule such as:
  "Do not produce broad artifacts or run full check matrices unless explicitly
  asked."
- Keep zip archives as an example only if useful.

### 8. Clean Up `GENERAL_DEVELOPMENT_PLAYBOOK.md`

- Remove copied general hygiene rules from the git section.
- Keep the git section focused on git behavior.
- Point to `AGENTS.md` or a canonical context-hygiene section for operational
  defaults.

### 9. Review Templates

Check these files for duplicate or overly long shared rules:

- `templates/AGENTS.template.md`
- `templates/AGENT_WORKING_AGREEMENTS.template.md`

Keep project-local templates concise while preserving the core behavior.

### 10. Strengthen Verification Guidance

- In the verification section, repeat the concrete check that new files under
  `templates/`, `patterns/`, or `checklists/` require `INDEX.md` updates.
- Continue using `git diff --check` for documentation-only changes.

### 11. Add Instruction Style Guidance

Add a short style rule for instruction documents:

- Use imperative voice.
- Prefer one rule per bullet.
- Avoid long nested conditionals.
- Avoid filler, narration, and non-actionable prose.

### 12. Add Scope Expansion Protocol

- Add an explicit rule to ask before expanding the task scope.
- Allow proceeding only when the expansion is required to satisfy the user's
  stated goal and is low-risk.

### 13. Add Exceptions For Broad Reads Or Checks

Clarify when broad scans, longer logs, or larger check suites are justified:

- explicit user request;
- incident debugging;
- unclear failure source after targeted search;
- release or pre-commit verification where the user asked for that scope.

### 14. Consider Final Response Examples

- Add 2-3 tiny examples of concise final responses versus overly verbose
  responses.
- Prefer putting examples in a pattern or working-agreements template instead of
  bloating always-loaded `AGENTS.md`.

## Suggested Implementation Order

1. Refactor `AGENTS.md` grouping and deduplication.
2. Add `patterns/FIRST_MESSAGE_HANDLING.md` and update `INDEX.md`.
3. Clean up `updates/` wording in `AGENTS.md` and templates.
4. Clean up `GENERAL_DEVELOPMENT_PLAYBOOK.md`, especially the git section.
5. Review templates for repeated shared guidance.
6. Run `git diff --check`.
7. Reread changed files with targeted ranges.

## Verification Ideas

- Confirm no duplicated "do not read large files in full" rule remains in
  `AGENTS.md`.
- Confirm `INDEX.md` references any new pattern.
- Confirm `GENERAL_DEVELOPMENT_PLAYBOOK.md` git section contains git-specific
  rules only.
- Confirm `updates/` remains documented as maintenance-only intake.
