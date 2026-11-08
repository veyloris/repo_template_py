# Security hygiene

This document describes the security controls the scaffold provides for
`my-app`. The posture is best practice and best effort: hygiene, not audit
requirements. Nothing here is a compliance attestation, and no formal audit
obligation exists unless the instantiating project adds one and says so.

Statements below describe what the scaffold ships. They become true of a
project only once it is configured that way.

> Template note: add a section for each integration, input boundary, or
> destructive path once the project has real ones.

## Supply chain

- Dependencies are locked in `uv.lock` with hashes. CI installs with
  `uv sync --locked`, which fails on a lock that is stale against
  `pyproject.toml` and verifies every download against its recorded hash.
- Dev tools (ruff, pyright, pytest) are dependencies in the same lock, so
  pre-commit and CI run the exact versions a developer runs.
- GitHub Actions workflows are audited by zizmor on every PR (see
  [security.yml](../../.github/workflows/security.yml)). The action pinning
  policy is enforced through [.github/zizmor.yml](../../.github/zizmor.yml):
  every action is pinned to a full commit SHA with the tag in a trailing
  comment. Renovate keeps these digests and the lock current.
- Runtime dependency CVEs are gated by Trivy in the same workflow, which reads
  `uv.lock` and leaves the dev group out by default. The gate's facts
  (severity, ignore file, pin locations) live in the "CVE triage manifest"
  section of [AGENTS.md](../../AGENTS.md), which the `/cve-ci-triage` skill
  consumes.
- Publishing is not included. A project that publishes to PyPI uses trusted
  publishing (OIDC from a workflow), never a stored API token, and records
  that as a D-### entry.

## Secrets

- Secrets never appear in git, CI logs, or build artifacts. gitleaks runs in
  pre-commit and TruffleHog in CI to catch the cases where that rule slips.
- Configuration that carries a secret is read from the environment at run
  time; `.env` and `.envrc` are gitignored.

## Untrusted input

Files, archives, and network responses the tool reads are data, not code.
Parse them with library parsers, never `eval`/`exec`/`pickle`, and bound what
they can make the tool allocate. Ruff's bandit rules (`S`) flag the common
cases in CI.

## Reporting a vulnerability

Report security issues privately through the repository's GitHub Security
Advisories ("Report a vulnerability" under the Security tab) rather than
opening a public issue.
