#!/usr/bin/env bash
# Install the agentic-sdd workflow into another repo's .claude/ folder.
# Usage: bash scripts/install.sh /path/to/target/repo [--force] [--with-ci]
#   --force     overwrite an existing .claude/settings.json instead of merging
#   --with-ci   also copy the Node/.NET build-and-test GitHub Actions workflow
#               into the target repo's .github/workflows/ci.yml
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$SRC_DIR/plugins/agentic-sdd"

TARGET=""
FORCE=""
WITH_CI=""
for arg in "$@"; do
  case "$arg" in
    --force)    FORCE="--force" ;;
    --with-ci)  WITH_CI="1" ;;
    -*)         echo "Unknown option: $arg" >&2; exit 1 ;;
    *)          [ -z "$TARGET" ] && TARGET="$arg" || { echo "Unexpected argument: $arg" >&2; exit 1; } ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Usage: bash scripts/install.sh /path/to/target/repo [--force] [--with-ci]" >&2
  exit 1
fi
if [ ! -d "$TARGET" ]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

DEST="$TARGET/.claude"
mkdir -p "$DEST"

echo "Installing agentic-sdd into $DEST ..."

# Copy components.
for d in agents commands skills tools; do
  rm -rf "${DEST:?}/${d:?}"
  cp -R "$PLUGIN/$d" "$DEST/$d"
  echo "  + $d/"
done
# rules/: replace the template's rules (00–89) but keep the project's curated 9x rules.
mkdir -p "$DEST/rules"
find "$DEST/rules" -maxdepth 1 -name '[0-8][0-9]-*.md' -delete
cp "$PLUGIN/rules/"*.md "$DEST/rules/"
echo "  + rules/ (curated 9x-* rules preserved)"

# Plugin content references ${CLAUDE_PLUGIN_ROOT}; in a copy install that root is .claude/.
find "$DEST/agents" "$DEST/commands" "$DEST/skills" -name '*.md' -print0 \
  | xargs -0 sed -i.agentic-bak 's#\${CLAUDE_PLUGIN_ROOT}#.claude#g'
find "$DEST" -name '*.agentic-bak' -delete
chmod +x "$DEST/tools/"*.py 2>/dev/null || true

# Hooks: copy scripts and make them executable.
mkdir -p "$DEST/hooks/scripts"
cp -R "$PLUGIN/hooks/scripts/." "$DEST/hooks/scripts/"
chmod +x "$DEST/hooks/scripts/"*.sh
echo "  + hooks/scripts/"

# settings.json: merge if one exists and jq is available, else write the template.
TEMPLATE="$PLUGIN/settings.template.json"
SETTINGS="$DEST/settings.json"
if [ -f "$SETTINGS" ] && [ "$FORCE" != "--force" ]; then
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq -s '.[0] * .[1]' "$SETTINGS" "$TEMPLATE" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "  ~ settings.json (merged with existing)"
  else
    cp "$TEMPLATE" "$DEST/settings.agentic-sdd.json"
    echo "  ! existing settings.json kept; wrote settings.agentic-sdd.json — merge the \"hooks\" and \"permissions\" keys manually (or install jq)."
  fi
else
  cp "$TEMPLATE" "$SETTINGS"
  echo "  + settings.json"
fi

# Drop a pointer to the workflow docs if the target has no CLAUDE.md guidance yet.
if [ ! -f "$TARGET/CLAUDE.md" ]; then
  cat > "$TARGET/CLAUDE.md" <<'MD'
# Project guidance

This project uses the **agentic-sdd** Spec-Driven Development + TDD workflow.
See `.claude/rules/` for the enforced rules and run `/feature <description>` to start.
Loop: /spec → /plan → [per slice: /tdd → /implement → commit] → /e2e → /qa → /review → /create-pr → /triage → /curate → /ship
Bugs and small fixes: `/fix <description>`.
MD
  echo "  + CLAUDE.md (starter)"
fi

# Optional: copy the build-and-test CI workflow into the target repo.
if [ -n "$WITH_CI" ]; then
  mkdir -p "$TARGET/.github/workflows"
  CI_DEST="$TARGET/.github/workflows/ci.yml"
  if [ -f "$CI_DEST" ] && [ "$FORCE" != "--force" ]; then
    cp "$SRC_DIR/templates/github-ci.yml" "$TARGET/.github/workflows/agentic-sdd-ci.yml"
    echo "  ! existing ci.yml kept; wrote agentic-sdd-ci.yml instead (use --force to overwrite ci.yml)."
  else
    cp "$SRC_DIR/templates/github-ci.yml" "$CI_DEST"
    echo "  + .github/workflows/ci.yml (Node/.NET build + test)"
  fi
fi

# Keep visual-QA captures out of git.
if [ -d "$TARGET/.git" ] && ! grep -qx '.qa-visual/' "$TARGET/.gitignore" 2>/dev/null; then
  printf '\n# agentic-sdd visual QA captures\n.qa-visual/\n' >> "$TARGET/.gitignore"
  echo "  + .gitignore (.qa-visual/)"
fi

echo "Done. Open $TARGET with Claude and run /feature to begin."
