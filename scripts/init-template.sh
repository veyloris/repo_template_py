#!/usr/bin/env bash
# Renames the template's placeholders to your project's real values.
#
# Usage:
#   ./scripts/init-template.sh <owner/repo> <distribution-name>
#
# Example:
#   ./scripts/init-template.sh acme/widget-tool widget-tool
#
# The distribution name is what `uv tool install` and the console script use
# (widget-tool); the import name is derived from it (widget_tool). This
# rewrites every placeholder across the working tree (myorg/my-app, my-app,
# my_app), renames src/my_app/, dates the scaffold decision in
# docs/DECISIONS.md, removes the template-only workflow, re-locks, runs the
# checks, and deletes itself.
#
# Needs bash 4+ and GNU sed (Linux, or gnu-sed on macOS).

set -euo pipefail

if ((BASH_VERSINFO[0] < 4)); then
    echo "error: needs bash 4 or newer (this is $BASH_VERSION)" >&2
    exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <owner/repo> <distribution-name>" >&2
    echo "example: $0 acme/widget-tool widget-tool" >&2
    exit 2
fi

REPO="$1"
DIST="$2"
OLD_REPO="myorg/my-app"
OLD_DIST="my-app"
OLD_IMPORT="my_app"
IMPORT="${DIST//-/_}"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SELF="$ROOT/scripts/init-template.sh"
cd "$ROOT"

# Every check that can reject the input runs before the first file changes,
# so a refused name leaves the template untouched.
if [[ ! "$REPO" =~ ^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$ ]]; then
    echo "error: repository '$REPO' does not look like owner/repo" >&2
    exit 1
fi

# A normalized distribution name: lowercase, hyphen-separated, so the derived
# import name is a valid Python identifier.
if [[ ! "$DIST" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
    echo "error: distribution name '$DIST' must be lowercase letters and" \
        "digits, words joined by single hyphens" >&2
    exit 1
fi

# The rewrite and the leftover check both look for the placeholder text, so a
# new value that contains it would be rewritten twice or flagged forever.
for value in "$REPO" "$DIST"; do
    case "$value" in
        *myorg* | *my-app* | *my_app*)
            echo "error: '$value' contains a template placeholder (myorg, my-app, my_app)" >&2
            exit 1
            ;;
    esac
done

# The import name must not shadow something the package or its tests import.
case "$IMPORT" in
    tests | src | hypothesis | pyright | pytest | ruff)
        echo "error: '$IMPORT' collides with a project directory or dev dependency" >&2
        exit 1
        ;;
esac
if ! uv run --no-project --python 3.14 python -I -c '
import keyword, sys
name = sys.argv[1]
if keyword.iskeyword(name) or keyword.issoftkeyword(name) or name in sys.stdlib_module_names:
    sys.exit(1)
' "$IMPORT"; then
    echo "error: '$IMPORT' is a Python keyword or a standard-library module" >&2
    exit 1
fi

if [[ ! -d "src/$OLD_IMPORT" ]]; then
    echo "error: src/$OLD_IMPORT not found; this tree is not a fresh template" >&2
    echo "(if an earlier run failed after renaming, finish by hand from its last step)" >&2
    exit 1
fi

echo "==> Rewriting $OLD_REPO -> $REPO"
echo "==> Rewriting $OLD_DIST -> $DIST, $OLD_IMPORT -> $IMPORT"

# In a freshly `git init`-ed clone -- the README's "clone manually" flow, which
# does `rm -rf .git && git init` -- `git ls-files` exits 0 with NO output. A
# plain `||` fallback therefore never fires and the rewrite loop below iterates
# zero times, silently producing a half-renamed tree. Test for actual output,
# not just exit status.
files_to_rewrite() {
    if [[ -n "$(git ls-files 2>/dev/null | head -n 1)" ]]; then
        git ls-files -z
    else
        find . -type f \
            -not -path './.git/*' \
            -not -path './.venv/*' \
            -not -path './scripts/init-template.sh' \
            -print0
    fi
}

# The slug contains the distribution name, so it is swapped for a token first
# and the token for the new slug last; the name rewrites never see the slug.
TOKEN="@@INIT_TEMPLATE_REPO@@"
while IFS= read -r -d '' file; do
    case "$file" in
        ./scripts/init-template.sh | scripts/init-template.sh) continue ;;
        ./.git/* | .git/*) continue ;;
    esac
    if grep -q -e "$OLD_REPO" -e "$OLD_DIST" -e "$OLD_IMPORT" -- "$file" 2>/dev/null; then
        sed -i \
            -e "s|$OLD_REPO|$TOKEN|g" \
            -e "s|\\b$OLD_DIST\\b|$DIST|g" \
            -e "s|\\b$OLD_IMPORT\\b|$IMPORT|g" \
            -e "s|$TOKEN|$REPO|g" \
            -- "$file"
    fi
done < <(files_to_rewrite)

echo "==> Renaming src/$OLD_IMPORT -> src/$IMPORT"
mv "src/$OLD_IMPORT" "src/$IMPORT"

echo "==> Dating D-001"
sed -i "s|REPLACE-DATE|$(date +%F)|" docs/DECISIONS.md

# The todo this script just finished, and the workflow that tests this script,
# should not outlive it.
sed -i '/^- Replace the .* placeholders via .*init-template\.sh/d' AGENTS.md
rm -f .github/workflows/template.yml

# Re-lock under the new name and prove the renamed tree works before the
# script deletes itself. A half-renamed tree that reports success is worse
# than an error.
echo "==> Re-locking"
uv lock

echo "==> Verifying: tests, types, lint"
uv sync --locked
uv run --frozen pytest -q
uv run --frozen pyright
uv run --frozen ruff check .
uv run --frozen ruff format --check .

echo "==> Verifying no placeholders remain"
# grep exits 0 on a match, 1 on none, and 2 on an error; only 1 is clean.
status=0
remaining=$(grep -rIl -e "myorg" -e "$OLD_DIST" -e "$OLD_IMPORT" -e "REPLACE-DATE" . \
    --exclude-dir=.git --exclude-dir=.venv --exclude-dir='*cache*' \
    --exclude=init-template.sh) || status=$?
if [[ "$status" -ne 1 ]]; then
    echo "error: placeholder check failed (grep status $status):" >&2
    echo "$remaining" >&2
    echo "the tree is only partly renamed; fix these by hand" >&2
    exit 1
fi

echo "==> Removing init script"
rm -- "$SELF"

echo
echo "Done. Recommended next steps:"
echo "  1) Confirm LICENSE fits this project (the template ships MIT)."
echo "  2) Write the description in pyproject.toml and src/$IMPORT/cli.py."
echo "  3) Edit AGENTS.md to reflect this project's architecture and conventions."
echo "  4) Edit README.md (replace this template's content with your project's README)."
echo "  5) pre-commit install"
echo "  6) git add -A && git commit -m 'chore: initial commit from repo_template_py'"
