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
# my_app, MY_APP_), renames src/my_app/, dates the scaffold decision in
# docs/DECISIONS.md, re-locks, runs the checks, and deletes itself.

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <owner/repo> <distribution-name>" >&2
    echo "example: $0 acme/widget-tool widget-tool" >&2
    exit 2
fi

REPO="$1"
DIST="$2"

if [[ ! "$REPO" =~ ^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$ ]]; then
    echo "error: repository '$REPO' does not look like owner/repo" >&2
    exit 1
fi

# A normalized distribution name: lowercase, hyphen-separated, so the derived
# import name is a valid Python identifier.
if [[ ! "$DIST" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
    echo "error: distribution name '$DIST' must be lowercase letters and digits, words joined by single hyphens" >&2
    exit 1
fi

OLD_REPO="myorg/my-app"
OLD_DIST="my-app"
OLD_IMPORT="my_app"
OLD_UPPER="MY_APP"
IMPORT="${DIST//-/_}"
UPPER="${IMPORT^^}"

if [[ "$DIST" == "$OLD_DIST" ]]; then
    echo "error: refusing to rename to the placeholder values" >&2
    exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [[ ! -d "src/$OLD_IMPORT" ]]; then
    echo "error: src/$OLD_IMPORT not found; has the template already been renamed?" >&2
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

# Order matters: the repository slug contains the distribution name, so it is
# rewritten first. Hyphens are not word characters, so \bmy-app\b also matches
# inside names like my-app-extra; the placeholders are chosen not to occur that
# way in the template.
while IFS= read -r -d '' file; do
    case "$file" in
        ./scripts/init-template.sh | scripts/init-template.sh) continue ;;
        ./.git/* | .git/*) continue ;;
    esac
    if grep -q -e "$OLD_REPO" -e "$OLD_DIST" -e "$OLD_IMPORT" -e "$OLD_UPPER" "$file" 2>/dev/null; then
        sed -i \
            -e "s|$OLD_REPO|$REPO|g" \
            -e "s|\\b$OLD_DIST\\b|$DIST|g" \
            -e "s|\\b$OLD_IMPORT\\b|$IMPORT|g" \
            -e "s|${OLD_UPPER}_|${UPPER}_|g" \
            "$file"
    fi
done < <(files_to_rewrite)

echo "==> Renaming src/$OLD_IMPORT -> src/$IMPORT"
mv "src/$OLD_IMPORT" "src/$IMPORT"

echo "==> Dating D-001"
sed -i "s|REPLACE-DATE|$(date +%F)|" docs/DECISIONS.md

# The todo this script just finished should not outlive it.
sed -i '/^- Replace the .* placeholders via .\/scripts\/init-template\.sh.$/d' AGENTS.md

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
if remaining=$(grep -rIl -e "myorg" -e "$OLD_DIST" -e "$OLD_IMPORT" -e "${OLD_UPPER}_" -e "REPLACE-DATE" . \
        --exclude-dir=.git --exclude-dir=.venv --exclude-dir='*cache*' \
        --exclude="$(basename "$0")" 2>/dev/null); then
    echo "error: placeholder values still present in:" >&2
    echo "$remaining" >&2
    echo "the tree is only partly renamed; fix these before rerunning" >&2
    exit 1
fi

echo "==> Removing init script"
rm -- "$0"

echo
echo "Done. Recommended next steps:"
echo "  1) Confirm LICENSE fits this project (the template ships MIT)."
echo "  2) Edit AGENTS.md to reflect this project's architecture and conventions."
echo "  3) Edit README.md (replace this template's content with your project's README)."
echo "  4) pre-commit install"
echo "  5) git add -A && git commit -m 'chore: initial commit from repo_template_py'"
