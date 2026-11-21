## Windows Command Policy

### Windowless Git

- Start the actual Git executable with console creation disabled. For .NET
  use `UseShellExecute = false` and `CreateNoWindow = true`; in Node use
  `windowsHide: true` with `shell: false`. Capture output and errors and retain
  the exit code. For Git for Windows, resolve the native binary behind any
  launcher before starting it from a process without a console.
- Apply the same guarantee to Git's descendants, including pagers, editors,
  hooks, and credential helpers, and to every Git launch inside tests and
  automation. Disable interactive components when the operation supports it.
  Hiding the parent, redirecting output, and restoring focus after a flash
  are insufficient. Audit the launch path before the first run and stop if
  any required process may still open a window. Do not rerun a path that
  already interrupted the user until the launch mechanism is corrected.

### Shell And Networking

- Prefer PowerShell-native networking commands such as `Invoke-RestMethod` and
  `Invoke-WebRequest` instead of `curl.exe`.
- When an HTTP/API write body contains Russian or other non-ASCII text, do not
  pass JSON to `Invoke-RestMethod` or `Invoke-WebRequest` as a plain `-Body`
  string. Prefer a client that sends UTF-8 JSON by default, such as Node
  `fetch`, or explicitly send UTF-8 bytes with a content type that includes
  `charset=utf-8`.
- Do not probe for `curl.exe` with `where.exe curl` or `Get-Command curl` unless
  the user explicitly asks for curl diagnostics.
- Prefer trusted helper binaries from `%USERPROFILE%\.codex\bin` before
  WindowsApps or System32 shims.
- If Windows or antivirus tools block agent commands with `Access denied`,
  trust narrow agent-owned tool folders such as `.codex\.sandbox-bin\` and
  `.codex\bin\`; do not add broad exclusions for System32 or PowerShell itself.
