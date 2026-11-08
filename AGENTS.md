### Security posture
Security is best practice and best effort: hygiene, not audit requirements. No
formal audit or compliance obligation exists unless this project adds one and
says so here. The controls the scaffold ships (hash-locked dependencies,
hash-pinned actions, secret and CVE scanning) are described in
[docs/operations/security.md](docs/operations/security.md).

### Unfinished Todos
- Replace the `my-app` / `my_app` / `myorg` placeholders via `./scripts/init-template.sh`
- Confirm `LICENSE` fits this project (the template ships MIT)
- Adjust `docs/operations/security.md` once the project has real integrations
- Confirm the "CVE triage manifest" section below reflects this project's real
  gates -- the init script rewrites the repository name, not the workflow facts
- Replace this file's "Common Tasks", "Key Paths", and "Architecture" sections with project-specific content

## Common Tasks
- Set up: `uv sync` (creates `.venv` from `uv.lock`)
- Test: `uv run pytest`
- Lint and format: `uv run ruff check .` and `uv run ruff format .`
- Type-check: `uv run pyright` (strict)
- Run: `uv run my-app --help`
- Install as a tool: `uv tool install .`
- Hooks: `pre-commit install` once per clone (installs commit, commit-msg,
  and pre-push hooks; tests run at pre-push)
- Add a dependency: `uv add <pkg>` (dev tool: `uv add --dev <pkg>`); commit
  `pyproject.toml` and `uv.lock` together
- Security scans: [security.yml](.github/workflows/security.yml) runs Trivy filesystem, TruffleHog, and zizmor on every PR (hash-pinned public scanners)

## Key Paths
| Path | Purpose |
|---|---|
| `src/my_app/cli.py` | argparse entry point (`my-app` console script) |
| `src/my_app/__main__.py` | `python -m my_app` |
| `tests/` | pytest suite, mirroring the package |
| `docs/DECISIONS.md` | Decision log (D-### entries) |
| `docs/migrations/` | Phased plans with validation appendices (see its README) |
| `docs/development/` | Doctrine: testing.md; local dev notes |
| `docs/operations/` | Runbooks and security.md |
| `.github/workflows/` | CI: validate and security scans on PR |

## Architecture
- **stdlib first**: argparse for the CLI, `logging` for diagnostics,
  `pathlib` for paths. A third-party dependency earns its place with a D-###
  entry.
- **src layout**: tests import the installed package, never the working tree,
  so a packaging mistake fails in tests rather than for users.
- **Typed package**: `py.typed` ships, and pyright runs strict over `src` and
  `tests`.

## Development Patterns

**IMPORTANT:** If development conflicts with these ideas, STOP and outline the
conflict to the user and ask for input.

- All development follows TDD. Tests are written before implementation;
  "write and see if it runs" is not a development strategy here.
- Development is modular and extensible: clean architecture with long-term
  thinking. Features fall out of deliberate architecture decisions rather
  than being stapled on. Composition over inheritance.
- The domain core is pure Python with no I/O -- unit and property tests only.
  I/O lives in adapters (files, subprocesses, devices, network), which get
  integration and golden-file tests. See
  [docs/development/testing.md](docs/development/testing.md).
- Purity is not enough on its own: pure code must also be *reachable* without
  I/O. Split load from compute and export the compute.

### Performance

- A performance claim needs a measurement, not a subtraction. "The rest must
  be X" is a hypothesis -- profile or benchmark it before scoping work
  against it.
- Every benchmark states a written acceptance target and its rationale. A
  benchmark with no target cannot fail, so it cannot regress.
- No wall-clock assertions in tests; shared runners are too noisy. Only
  correctness invariants may fail a benchmark.

## Conventions

- Decisions worth carrying forward go in
  [docs/DECISIONS.md](docs/DECISIONS.md) as D-### entries, recorded when
  made.
- Plans above moderate complexity go in `docs/migrations/` with creation
  date and state (notstarted | started | complete), including before/after
  validation checks recorded in an appendix tracker. See
  [docs/migrations/README.md](docs/migrations/README.md).
- Backlog is GitHub issues in this repo.
- No emojis in documentation.
- Security controls are documented in
  [docs/operations/security.md](docs/operations/security.md). When a feature
  adds an integration, an input boundary, or a destructive path, that doc
  gains a short section for it, referencing the D-### entries and plan doc
  that shaped it.

## CVE triage manifest

Consumed by the `/cve-ci-triage` skill (user-level, `~/.claude/skills/`). The
skill is the method; this section is this repository's facts. A repo cut from
this template is onboarded by running `./scripts/init-template.sh`, which
rewrites the `Repository` field below along with every other placeholder. No
hand-editing is required here.

- **Repository:** github.com/myorg/my-app
- **Ecosystem:** python (`uv.lock`)
- **Scan gates:**
  | Workflow name | Job | File | Trigger | Target | Severity | ignore-unfixed | Red signal |
  |---|---|---|---|---|---|---|---|
  | Security Scans | Trivy Repository Scan | `.github/workflows/security.yml` | PR to main, Monday 14:00 UTC, dispatch | filesystem (`.`) | CRITICAL,HIGH | true | failed run only -- no tracking issue is opened |
- **Ignore files:** `.trivyignore.yaml` (repo root), YAML form, wired through the
  `trivyignores` input on the scan step.
- **Pin locations:** `uv.lock` (every runtime and dev dependency, with hashes),
  bounded by the specifiers in `pyproject.toml`. Trivy gates the runtime
  dependencies only: it leaves the dev group out by default, and the dev tools
  never ship to users. No container image or tool binary is built, so nothing
  else is CVE-gated.
- **Pre-authorized merges:** trivyignore entries, dependency bumps, and green
  Renovate PRs may be self-merged. Secrets and workflow permissions are not.
- **Repo notes:**
  - There is no tracking issue and no `issues: write` permission. A failed
    scheduled run on main is the only red signal, so check
    `gh run list --workflow "Security Scans"` rather than `gh issue list`.
  - Bump a vulnerable dependency with `uv lock --upgrade-package <name>`; a
    transitive one may need a raised floor in `pyproject.toml` first.
  - The weekly Monday run is the one that catches newly published CVEs against
    unchanged code; a PR run only sees the PR's own tree.
