# repo_template_py

Opinionated template for Python command-line tools and libraries, installed
with `uv tool install`. Stand up a new repo with a typed src-layout package,
strict type checking, a tested CLI, pre-commit, and hash-pinned CI in a few
minutes.

## What you get

| Concern | Choice |
|---|---|
| Packaging | [uv](https://docs.astral.sh/uv/) with the `uv_build` backend, src layout, `py.typed` |
| Python | 3.14 (`.python-version`; uv installs it, locally and in CI) |
| CLI | stdlib `argparse` with subcommands; console script and `python -m` |
| Lint and format | [ruff](https://docs.astral.sh/ruff/) with pycodestyle, pyflakes, isort, bugbear, pyupgrade, bandit, and friends |
| Types | [pyright](https://github.com/microsoft/pyright) in strict mode over `src` and `tests` |
| Tests | pytest with warnings as errors; hypothesis for property tests |
| Tool versions | ruff, pyright, pytest, and hypothesis pinned once in `uv.lock`; pre-commit and CI run them from there |
| Pre-commit | gitleaks, uv lock check, ruff, pyright, shellcheck, JSON-schema checks for workflows and Renovate; pytest at pre-push |
| CI | GitHub Actions: PR validate (locked sync, lint, format, types, tests, built-wheel smoke run), security scans (Trivy filesystem, TruffleHog, zizmor), and a template-only job that instantiates the template |
| Security hygiene | `docs/operations/security.md`: the controls the scaffold ships, stated as hygiene rather than compliance claims |
| Process scaffolding | Decision log (`docs/DECISIONS.md`), migration-plan convention with validation appendices (`docs/migrations/`), testing doctrine (`docs/development/`) |

## Use this template

### Option 1: GitHub "Use this template"

Click `Use this template` on the GitHub UI, then run the rename script in the new clone:

```bash
./scripts/init-template.sh yourorg/your-tool your-tool
```

### Option 2: clone manually

```bash
git clone https://github.com/veyloris/repo_template_py.git your-tool
cd your-tool
rm -rf .git && git init
./scripts/init-template.sh yourorg/your-tool your-tool
```

The script rewrites the placeholders (`myorg/my-app`, the distribution name
`my-app`, and the import name `my_app`), renames `src/my_app/`, dates the
scaffold decision, removes the template-only workflow, re-locks, and runs the
checks before deleting itself. It refuses names that contain a placeholder or
that Python cannot import cleanly (keywords, standard-library modules, the dev
tools, `tests`, `src`) before changing anything. It needs bash 4+ and GNU sed.

## Quickstart after rename

```bash
uv sync                  # .venv from uv.lock
uv run pytest            # tests
uv run pyright           # strict types
uv run ruff check .      # lint
uv run your-tool version # prints the installed version
pre-commit install       # commit + pre-push hooks
```

## Layout

```
.
├── src/my_app/                 # the package: cli.py, __main__.py, py.typed
├── tests/                      # pytest suite, mirroring the package
├── docs/
│   ├── DECISIONS.md            # decision log: D-### entries, recorded when made
│   ├── development/            # testing.md doctrine, local dev notes
│   ├── migrations/             # phased plans with validation appendices (see README.md there)
│   └── operations/             # runbooks, security.md (controls the scaffold ships)
├── scripts/init-template.sh    # rename helper
├── .github/workflows/          # validate (PR) + security (PR + weekly) + template (template repo only)
├── .pre-commit-config.yaml     # gitleaks + lint + format + types + filesystem checks
├── pyproject.toml              # metadata, dev tools, ruff/pyright/pytest config
├── uv.lock                     # every dependency, with hashes
└── AGENTS.md                   # project-level agent instructions (template)
```

## Opinions baked in

- **TDD, mechanically.** Tests are written before implementation. The domain
  core is pure Python with no I/O (unit and property tests only); I/O lives in
  adapters tested with integration and golden-file tests. The full doctrine is
  in [docs/development/testing.md](docs/development/testing.md).
- **Decisions get written down.** Architecture and process decisions go in
  [docs/DECISIONS.md](docs/DECISIONS.md) as short D-### entries when they are
  made. Anything above moderate complexity gets a plan doc in
  `docs/migrations/` with a state field and a before/after validation
  appendix ([convention](docs/migrations/README.md)).
- **stdlib first.** argparse, logging, pathlib. A dependency earns its place.
- **One version source.** Dev tools are locked dependencies, not separate
  pre-commit pins, so a hook can never lint with a different ruff than CI.
- **Strict types everywhere.** pyright strict covers the tests too; a test
  that cannot be typed is usually a test of the wrong seam.
- **Pin everything.** All GitHub Actions are SHA-pinned and every dependency is
  hash-locked. Renovate bumps them with a paper trail.
- **Pre-commit is a superset of CI.** The Python checks run in both with the
  same versions from `uv.lock`. The shell, schema, and filesystem hooks run
  only locally, so install the hooks in every clone.

## What is intentionally not included

- A container build. Add a Dockerfile and a build workflow when the project
  is a service, and record it as a decision.
- Publishing to PyPI. Add a workflow using trusted publishing (OIDC) when the
  project is ready to publish.
- A task runner. `uv run` already names every command.
- Benchmark tooling. The first hot path adds it, with a written target.

## Security posture

Security here is best practice and best effort: hygiene, not audit
requirements. The template makes no compliance claims and carries no audit
obligations; a project that has them adds them explicitly.
[docs/operations/security.md](docs/operations/security.md) describes the
controls the scaffold ships (hash-locked dependencies, hash-pinned actions,
secret and CVE scanning). It describes the scaffold, not your project:
statements there become true of your project only once you have configured it
that way.

## Reporting a vulnerability

Report security issues privately through this repository's GitHub Security
Advisories ("Report a vulnerability" under the Security tab) rather than
opening a public issue.

## License

[MIT](LICENSE).
