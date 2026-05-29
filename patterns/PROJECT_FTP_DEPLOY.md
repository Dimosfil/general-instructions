# Project FTP Deploy

Use this pattern when the user asks `gi ftp`, `gi ftp config`, `gi upload ftp`,
`gi deploy ftp`, `gi zaley na ftp`, `gi залей на фтп`, `ги фтп`, or
`ги фтп конфиг`.

## Intent

- Treat `gi ftp` and `ги фтп` as requests to upload the current project's
  configured build output to FTP, FTPS, or SFTP.
- Treat `gi ftp config`, `gi ftp конфиг`, and `ги фтп конфиг` as requests to
  create, inspect, or update the current project's FTP/SFTP config without
  uploading.
- Keep FTP/SFTP settings in a separate project-local config file, not in chat,
  shared instructions, README prose, or global agent memory.
- Prefer `tools/deploy/ftp.local.json` for the project-local config.
- Keep `tools/deploy/ftp.local.json` untracked when it contains hostnames,
  usernames, passwords, tokens, private keys, or private remote paths.
- Commit only a redacted example such as `tools/deploy/ftp.local.example.json`
  when the project wants a documented shape.

## Config Shape

Use this JSON shape unless project-local instructions define a stricter one:

```json
{
  "protocol": "sftp",
  "host": "example.com",
  "port": 22,
  "username": "deploy",
  "passwordEnv": "PROJECT_FTP_PASSWORD",
  "privateKeyPath": null,
  "localPath": "dist/",
  "remotePath": "/www/example/",
  "cleanRemote": false
}
```

- `protocol` must be one of `ftp`, `ftps`, or `sftp`.
- `host`, `username`, `localPath`, and `remotePath` are required.
- Use `passwordEnv` or `privateKeyPath` instead of storing a password when
  practical.
- If a user explicitly provides credentials in chat, write them only to the
  project-local untracked config after confirming the destination file; do not
  echo secrets back in later messages.
- Never store FTP credentials in this shared instruction library.

## Workflow

- For `gi ftp config` / `ги фтп конфиг`, create or update
  `tools/deploy/ftp.local.json` from the template shape, ask only for missing
  required values, and remind the user when secrets are referenced through
  environment variables instead of stored in the file.
- When writing config values, preserve existing fields unless the user asks to
  change them.
- When showing config status, redact `host`, `username`, `password`,
  `passwordEnv` values that reveal private names, `privateKeyPath`, and private
  remote paths unless the user explicitly asks to inspect the local file.
- Read project-local instructions, runbook, package/build manifests, and
  `tools/deploy/ftp.local.json` before asking for upload details.
- If the config is missing, look for a redacted example in
  `tools/deploy/ftp.local.example.json`, then ask the user for the missing
  non-secret details and where they want secrets stored.
- If `localPath` is missing or stale, run the documented production build before
  upload. If no build contract exists, ask one short clarification question.
- Prefer existing project deploy scripts when they read the same config and do
  not expose secrets in command output.
- If no deploy script exists, use an available standard tool appropriate to the
  protocol, such as WinSCP, `sftp`, `scp`, `lftp`, or `curl`, without printing
  secrets.
- Do not delete or replace remote files unless `cleanRemote` is true and the
  project-local instructions or user request clearly allow that behavior.
- After upload, report the protocol, host, remote path, local artifact path, and
  verification performed. Do not print passwords, tokens, private keys, or full
  credential-bearing command lines.

## Verification

- Confirm the local upload source exists before starting transfer.
- Prefer a dry listing or checksum/size comparison when the tool and server
  support it.
- If verification cannot be performed, say so briefly and report the transfer
  command result without exposing secrets.
