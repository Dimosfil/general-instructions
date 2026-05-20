# Git Workflow

Use this pattern for project Git policy, commit requests, and commit message
language preferences.

## Default Policy

- The agent may edit and verify files.
- The user reviews and commits unless they explicitly ask the agent to commit.
- Do not run `git commit`, `git push`, branch changes, destructive git commands,
  or history rewrites without an explicit user request.
- Treat `gi коммит`, `gi пуш`, `gi коммит пуш`, and `gi только пуш` as explicit
  git finish requests for the current project.
- `gi коммит` means commit only.
- `gi пуш` means commit the scoped current changes, then push the current branch.
- `gi коммит пуш` means the same as `gi пуш`.
- `gi только пуш` means push existing local commits only; do not create a new
  commit for this command.
- Exception: a successful `gi обновить` / `gi обновись` is an explicit request to
  commit and push the resulting instruction-kit update changes, if the current
  project is a git repository with a configured remote and the changes are
  limited to instruction-kit files.
- If the current project is not a git repository, still apply successful GI
  instruction-kit updates when possible, then skip commit/push and report that
  git is unavailable for this project.
- Treat dirty worktrees as normal.
- Do not revert user changes unless the user explicitly asks.
- Keep changes scoped to the current task.
- Do not commit secrets, credentials, local databases, logs, or generated
  caches.
- Prefer `git diff --stat` and targeted file checks over full diff dumps.

## Finish Workflow

Before any `gi коммит`, `gi пуш`, `gi коммит пуш`, or `gi только пуш` action:

- inspect `git status --short`;
- inspect staged and unstaged changes with compact stats or targeted checks;
- identify the current branch and configured remote;
- keep user/unrelated changes out of the commit;
- stop and explain the blocker if scope is ambiguous, conflicts are present,
  secrets may be included, the project is not a git repository, no remote is
  configured for a push, or push fails.

For `gi коммит`:

- stage only scoped task changes;
- create one commit using the configured commit-message language preferences;
- do not push.

For `gi пуш` and `gi коммит пуш`:

- stage only scoped task changes;
- create one commit using the configured commit-message language preferences;
- push the current branch to its configured upstream.

For `gi только пуш`:

- do not stage files;
- do not create a commit;
- push only already committed local work on the current branch.

## Commit Message Languages

Projects may keep commit message preferences in:

```text
tools/project-memory/git-preferences.json
```

Default language policy:

- English is the primary commit-message language.
- Additional languages are optional.
- When at least one additional language is selected, write commit messages in
  English plus the selected language or languages.
- Keep each language concise.

Suggested commit format:

```text
English summary

<Selected language>: translated summary
```

If multiple additional languages are selected, add one translated summary line
per language.

## Supported Startup Choices

Offer these five languages when a project is configured:

- English
- Russian
- Spanish
- German
- French

English should be selected by default and treated as the primary language.

## Selection Workflow

During project bootstrap, copy the default preferences file and do not pause to
ask about commit-message languages.

When the user asks in chat to configure commit-message languages, update
`tools/project-memory/git-preferences.json` directly and briefly summarize the
new setting. Ask a short clarification only if the requested languages are
ambiguous.

Treat `gi commit language`, `gi коммит язык`, `ги коммит язык`, and older
`gi язык коммита` forms as the short shared-instruction command forms for this
workflow.

Do not use commit-language commands to change the agent's user-facing working
language. That is configured separately with `gi system language`, `gi систем
язык`, or `ги систем язык` in `tools/project-memory/system-preferences.json`.

Do not infer additional commit-message languages from the user's UI language or
message language. If the user says only "choose/select commit language" without
naming languages, ask which additional languages to enable, or offer the
supported list.

For ambiguous commit-language selection, present a concise numbered Markdown
checklist instead of a prose-only list. Show `English` as always selected,
explain that it is the required primary commit-message language, and mark
current additional languages as checked. Ask the user to reply with language
names or numbers.

Example:

```markdown
Which additional commit-message languages should be enabled?

English is the required primary commit-message language and cannot be disabled.
Reply with numbers or language names for any additional languages to enable.

1. [x] English (primary, required)
2. [x] Russian
3. [ ] Spanish
4. [ ] German
5. [ ] French
```

When reporting the change, mention the plain path
`tools/project-memory/git-preferences.json`. Do not emit malformed markdown
links or placeholder links.

Do not answer a chat request only by telling the user to run a PowerShell
command. The selector is a helper for users who explicitly want to run the
configuration themselves:

```powershell
.\tools\select-git-commit-languages.ps1
```

The startup script may also expose the same choice:

```powershell
.\tools\agent-start.ps1 -ConfigureGitCommitLanguages
```

Run the same command any time the user asks to change commit language
preferences.

The script should save the selected languages in project memory so future agents
working in the same project can reuse the preference.
