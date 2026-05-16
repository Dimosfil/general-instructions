# Git Workflow

Use this pattern for project Git policy, commit requests, and commit message
language preferences.

## Default Policy

- The agent may edit and verify files.
- The user reviews and commits unless they explicitly ask the agent to commit.
- Do not run `git commit`, `git push`, branch changes, destructive git commands,
  or history rewrites without an explicit user request.
- Treat dirty worktrees as normal.
- Do not revert user changes unless the user explicitly asks.
- Keep changes scoped to the current task.
- Do not commit secrets, credentials, local databases, logs, or generated
  caches.
- Prefer `git diff --stat` and targeted file checks over full diff dumps.

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

Only run or offer the selector when the user explicitly asks to configure commit
message languages:

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
