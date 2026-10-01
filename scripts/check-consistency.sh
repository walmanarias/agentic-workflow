#!/usr/bin/env bash
# Keeps the repo's many descriptions of the workflow from drifting apart.
# Checks: the canonical loop line appears verbatim everywhere it is described; README/plugin
# README counts match the files on disk; plugin.json and marketplace.json versions agree; every
# stack skill is in tools/stacks.json and vice versa; agent/command/skill frontmatter parses.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
P="$ROOT/plugins/agentic-sdd"
errors=0
err() { printf '  ✗ %s\n' "$1"; errors=$((errors + 1)); }

LOOP="$(grep -m1 '^/spec → ' "$P/rules/00-workflow.md")"
[ -z "$LOOP" ] && { echo "No canonical loop line in rules/00-workflow.md"; exit 1; }
echo "Canonical loop: $LOOP"
for f in CLAUDE.md README.md plugins/agentic-sdd/README.md \
         plugins/agentic-sdd/hooks/scripts/session-start.sh scripts/install.sh \
         plugins/agentic-sdd/skills/spec-driven-development/SKILL.md \
         plugins/agentic-sdd/commands/feature.md; do
  grep -qF -- "$LOOP" "$ROOT/$f" || err "$f does not contain the canonical loop line"
done

agents=$(find "$P/agents" -name '*.md' | wc -l | tr -d ' ')
commands=$(find "$P/commands" -name '*.md' | wc -l | tr -d ' ')
skills=$(find "$P/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
experts=$(find "$P/skills" -mindepth 1 -maxdepth 1 -type d -name '*-expert' | wc -l | tr -d ' ')
playbooks=$((skills - experts))
has() { sed 's/\*\*//g' "$ROOT/$1" | grep -q -- "$2"; }
for f in README.md plugins/agentic-sdd/README.md; do
  has "$f" "$agents lifecycle agents" || err "$f: expected '$agents lifecycle agents'"
  has "$f" "$playbooks workflow playbooks" || err "$f: expected '$playbooks workflow playbooks'"
  has "$f" "$experts stack-expert skills" || err "$f: expected '$experts stack-expert skills'"
done
has README.md "$commands commands" || err "README.md: expected '$commands commands'"
has README.md "$skills skills" || err "README.md: expected '$skills skills'"
for c in "$P"/commands/*.md; do
  name="/$(basename "$c" .md)"
  grep -qF -- "\`$name" "$ROOT/CLAUDE.md" || err "CLAUDE.md commands table is missing $name"
  grep -qF -- "$name" "$P/README.md" || err "plugin README is missing $name"
done
for a in "$P"/agents/*.md; do
  name="$(basename "$a" .md)"
  grep -qF -- "\`$name\`" "$ROOT/CLAUDE.md" || err "CLAUDE.md agents table is missing $name"
done

python3 - "$ROOT" <<'PY' || errors=$((errors + 1))
import json, os, sys, glob
root = sys.argv[1]; p = os.path.join(root, "plugins/agentic-sdd")
bad = 0
def err(m):
    global bad; bad += 1; print(f"  ✗ {m}")
plugin = json.load(open(os.path.join(p, ".claude-plugin/plugin.json")))
market = json.load(open(os.path.join(root, ".claude-plugin/marketplace.json")))
entry = next((x for x in market["plugins"] if x["name"] == plugin["name"]), None)
if not entry: err("marketplace.json has no entry for the plugin")
else:
    for where, v in (("marketplace.json version", market.get("version")), ("marketplace entry version", entry.get("version"))):
        if v != plugin["version"]: err(f"{where} {v} != plugin.json {plugin['version']}")
changelog = open(os.path.join(root, "CHANGELOG.md")).read()
if f"## {plugin['version']}" not in changelog: err(f"CHANGELOG.md has no '## {plugin['version']}' entry")
reg = json.load(open(os.path.join(p, "tools/stacks.json")))["skills"]
experts = {os.path.basename(d) for d in glob.glob(os.path.join(p, "skills/*-expert"))}
for s in sorted(experts - set(reg)): err(f"skill {s} missing from tools/stacks.json")
for s in sorted(set(reg) - experts): err(f"tools/stacks.json lists {s} but skills/{s} does not exist")
for s, spec in reg.items():
    for w in spec.get("with", []):
        if w not in reg: err(f"stacks.json: {s} pairs with unknown {w}")
try:
    import yaml
except ImportError:
    yaml = None; print("  (PyYAML not installed — frontmatter parse skipped)")
files = glob.glob(os.path.join(p, "agents/*.md")) + glob.glob(os.path.join(p, "commands/*.md")) + glob.glob(os.path.join(p, "skills/*/SKILL.md"))
for f in files:
    text = open(f).read()
    if not text.startswith("---\n"): err(f"{f}: no frontmatter"); continue
    fm = text.split("---\n", 2)[1]
    if yaml:
        try: data = yaml.safe_load(fm)
        except Exception as e: err(f"{f}: frontmatter does not parse: {e}"); continue
        if "description" not in data: err(f"{f}: no description")
        if "/agents/" in f and data.get("name") != os.path.basename(f)[:-3]: err(f"{f}: name != file name")
        if f.endswith("SKILL.md") and data.get("name") != os.path.basename(os.path.dirname(f)): err(f"{f}: name != folder")
        if "/agents/" in f and data.get("model") not in ("opus", "sonnet", "haiku", "inherit", None): err(f"{f}: unknown model {data.get('model')}")
sys.exit(1 if bad else 0)
PY

if [ "$errors" -gt 0 ]; then echo "consistency: $errors problem(s)"; exit 1; fi
echo "consistency: ok"
