# Instruction Kit Migrations

This folder contains accepted, ordered migrations for projects that copied this
instruction kit.

Consuming projects may read this folder when the user asks to check or apply
instruction updates. They must not read `updates/`; that folder is intake only
for maintaining this shared library.

Migration file names use:

```text
YYYY.MM.DD.N__short_description.md
```

Apply migrations in filename order and record applied migration IDs in
`tools/project-memory/instruction-kit.json`.
