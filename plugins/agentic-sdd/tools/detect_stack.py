#!/usr/bin/env python3
"""Detect which agentic-sdd stack-expert skills apply to a repo, from tools/stacks.json.

Usage: detect_stack.py [repo_dir] [--json]
Prints one line:  skills: a, b, c | runners: x, y   (or JSON with --json).
Scans package.json (deps + devDeps), pyproject.toml / requirements*.txt, and *.csproj,
up to 4 directories deep, skipping vendored/build dirs. Never fails: prints nothing on error.
"""
import json
import os
import re
import sys

SKIP_DIRS = {"node_modules", ".git", "bin", "obj", "dist", "build", ".next", ".venv", "venv", "__pycache__", ".expo", "Pods"}
MAX_DEPTH = 4


def walk(root):
    root_depth = root.rstrip(os.sep).count(os.sep)
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        if dirpath.count(os.sep) - root_depth >= MAX_DEPTH:
            dirnames[:] = []
        for f in filenames:
            yield os.path.join(dirpath, f), f


def collect(root):
    npm, py_text, cs_text = set(), "", ""
    for path, name in walk(root):
        try:
            if name == "package.json":
                with open(path, encoding="utf-8") as fh:
                    data = json.load(fh)
                for key in ("dependencies", "devDependencies", "peerDependencies"):
                    npm.update((data.get(key) or {}).keys())
            elif name == "pyproject.toml" or re.match(r"requirements.*\.txt$", name) or name in ("setup.cfg", "setup.py", "Pipfile"):
                with open(path, encoding="utf-8", errors="ignore") as fh:
                    py_text += "\n" + fh.read().lower()
            elif name.endswith(".csproj") or name in ("Directory.Packages.props", "Directory.Build.props"):
                with open(path, encoding="utf-8", errors="ignore") as fh:
                    cs_text += "\n" + fh.read()
        except (OSError, ValueError):
            continue
    return npm, py_text, cs_text


def py_has(text, pkg):
    return re.search(r"(^|[\s\"'\[,])" + re.escape(pkg.lower()) + r"([\s\"'<>=~!\[;,]|$)", text, re.M) is not None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = os.path.abspath(args[0] if args else os.environ.get("CLAUDE_PROJECT_DIR", "."))
    here = os.path.dirname(os.path.abspath(__file__))
    try:
        with open(os.path.join(here, "stacks.json"), encoding="utf-8") as fh:
            registry = json.load(fh)
    except (OSError, ValueError):
        return
    npm, py_text, cs_text = collect(root)
    skills = []
    for skill, spec in registry["skills"].items():
        hit = any(p in npm for p in spec.get("npm", [])) \
            or any(py_has(py_text, p) for p in spec.get("py", [])) \
            or any(m in cs_text for m in spec.get("csproj", []))
        if hit:
            for dep in spec.get("with", []):
                if dep not in skills:
                    skills.append(dep)
            if skill not in skills:
                skills.append(skill)
    runners = []
    for kind, table in registry.get("runners", {}).items():
        for marker, label in table.items():
            found = (marker in npm) if kind == "npm" else py_has(py_text, marker) if kind == "py" else (marker in cs_text)
            if found and label not in runners:
                runners.append(label)
    if "--json" in sys.argv:
        print(json.dumps({"skills": skills, "runners": runners}))
    elif skills or runners:
        print(f"skills: {', '.join(skills) or '-'} | runners: {', '.join(runners) or '-'}")


if __name__ == "__main__":
    main()
