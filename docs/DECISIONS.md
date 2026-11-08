# Decision Log

Format: D-###, date, status (accepted | proposed | superseded). Keep entries
short; link the discussion or plan doc when one exists. Record a decision the
moment it is made -- an unrecorded decision gets relitigated. When a plan doc
in docs/migrations/ will introduce decisions, it declares the numbers it
reserves so parallel work does not collide.

An entry says what was decided, the one or two live alternatives that were
rejected, and why. It does not restate the code.

## D-001 -- Scaffolded from repo_template_py (REPLACE-DATE, accepted)

This project was instantiated from repo_template_py: a src-layout package
built with uv_build, an argparse CLI, Python 3.14, the dev tools (ruff,
pyright strict, pytest, hypothesis) pinned once in uv.lock and run from it by
pre-commit and CI alike, pre-commit with a pre-push test tier, hash-pinned CI
with Trivy, TruffleHog, and zizmor, and the docs conventions in this
directory (this log, docs/migrations/ plan docs, docs/development/ doctrine).

Rejected at template level: a Taskfile (uv already names every command, so a
second runner adds a tool without adding a capability), and a container build
(the template targets tools installed with `uv tool install`; a service adds
its image build as its own decision). Deviations from the template's opinions
get their own D-### entries rather than silent divergence.
