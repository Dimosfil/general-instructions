# Build Output Policy Contract

Status: current accepted instruction behavior. Last checked: 2026-10-03.

## Purpose And Sources

Keep reproducible build artifacts separate from maintained inputs and source
version control while preserving runnable and deployable applications.

- Layout, cleanup, and verification source:
  `patterns/AGENTS_RUNTIME/09-build-and-install.md`.
- Git selection source: `patterns/GIT_WORKFLOW.md` and runtime module 16.
- Propagation: `2026.10.03.1__separate_build_output_from_source_git`.

## Invariants

- Rebuildable application bundles, executables, installers, and intermediate
  output use dedicated ignored directories with project-configured paths.
- Source, required source assets, dependency manifests/lockfiles, configuration,
  and build/packaging scripts remain versioned for clean-checkout generation.
- Directory names and automatic generation alone do not decide exclusion.
  Maintained static inputs, generated source, and database migrations require
  classification; approved output exceptions remain project-specific.
- Authorized cleanup updates consumers and removes only confirmed output from
  the index, preserving local artifacts and unrelated staged/user changes.
- Git finish excludes output but does not initiate product cleanup. Applying
  the instruction migration likewise updates rules rather than product files.
- Scoped index removals from authorized output cleanup may be committed; this
  exclusion does not prevent removing old output from source version control.
- Deployment consumes built artifacts even when source Git ignores them.

## Verification Cases

| Case | Required result |
| --- | --- |
| New build workflow | Output directory ignored before generation |
| Already tracked bundles | Scoped authorized index removal; local files preserved |
| Mixed static directory | Maintained inputs remain tracked |
| Generated source or database migration | Classify by purpose, not generation alone |
| Clean checkout | Documented prerequisites and build recreate required output |
| Packaging or deployment | Updated consumer uses the built artifact |
| Git finish with output changes | Output excluded; no unrelated product cleanup |
| Instruction update | Rules merged; product configuration and files preserved |
| Approved project exception | Exact output paths and storage approach documented |

Check scoped rule consistency, build/install/Git routes, entrypoint and context
budgets, migration metadata, and whitespace. This library does not itself build
an application; consumer projects verify their actual generation and run paths
when authorized build workflow work occurs.
