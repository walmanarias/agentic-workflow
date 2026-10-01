#!/usr/bin/env python3
"""AC traceability check: every acceptance criterion in a spec maps to at least one test.

Usage:
  ac_trace.py <spec.md | specs/<feature>/> [--tests PATH ...] [--base REF] [--all-tests] [--json]

- ACs are read from the spec's "Acceptance criteria" section (ids like AC-1, AC-12).
  An AC whose line contains "(E2E)" must also be referenced by an E2E test.
- Tests searched (in order of precedence):
    --tests PATH...  explicit files/dirs
    default          test files changed on this branch vs the merge-base with --base
                     (default: origin/HEAD, else main/master) — AC ids are per-spec, so
                     scoping to the branch avoids matching another feature's AC-1
    --all-tests      every test file in the repo
- A test "covers" AC-n when the id appears in the file (test name or comment) as a whole id
  (AC-1 does not match AC-10).
Exit 0 = all covered; 1 = gaps (listed); 2 = usage/spec error.
"""
import json
import os
import re
import subprocess
import sys

SKIP_DIRS = {"node_modules", ".git", "bin", "obj", "dist", "build", ".next", ".venv", "venv", "__pycache__", "coverage"}
TEST_RE = re.compile(
    r"(\.(test|spec|e2e)\.[cm]?[jt]sx?$)|(/__tests__/)|(^|/)(e2e|tests?)/|(^|/)test_[^/]*\.py$|_test\.py$|(^|/)conftest\.py$"
    r"|\.Tests/|\.UITests/|Tests?\.cs$")
E2E_RE = re.compile(r"(^|/)(e2e|playwright|cypress|detox|maestro|uitests?)(/|$)|\.e2e\.|\.UITests/|e2e", re.I)
CODE_EXT = (".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts", ".py", ".cs", ".yaml", ".yml", ".feature")


def git(*args):
    try:
        return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return ""


def default_base():
    ref = git("symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD").strip()
    for cand in ([ref] if ref else []) + ["origin/main", "main", "origin/master", "master"]:
        if git("rev-parse", "--verify", "--quiet", cand).strip():
            return cand
    return None


def parse_spec(path):
    if os.path.isdir(path):
        for name in ("spec.md",):
            if os.path.isfile(os.path.join(path, name)):
                path = os.path.join(path, name)
                break
        else:
            sys.exit(f"ac_trace: no spec.md in {path}")
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.search(r"^##\s+Acceptance criteria.*?$(.*?)(?=^##\s|\Z)", text, re.M | re.S | re.I)
    section = m.group(1) if m else text
    acs = {}
    for line in section.splitlines():
        for ac in re.findall(r"\bAC-(\d+)\b", line):
            key = f"AC-{ac}"
            acs.setdefault(key, False)
            if "(E2E)" in line or "(e2e)" in line:
                acs[key] = True
    return path, acs


def list_tests(paths, base, all_tests):
    files = []
    if paths:
        for p in paths:
            if os.path.isdir(p):
                for dp, dn, fn in os.walk(p):
                    dn[:] = [d for d in dn if d not in SKIP_DIRS]
                    files += [os.path.join(dp, f) for f in fn if f.endswith(CODE_EXT)]
            elif os.path.isfile(p):
                files.append(p)
        return files
    if not all_tests and base:
        mb = git("merge-base", base, "HEAD").strip()
        changed = git("diff", "--name-only", "--diff-filter=ACMR", mb or base).splitlines()
        changed += git("ls-files", "--others", "--exclude-standard").splitlines()
        files = [f for f in changed if TEST_RE.search(f) and f.endswith(CODE_EXT) and os.path.isfile(f)]
        if files:
            return files
    for dp, dn, fn in os.walk("."):
        dn[:] = [d for d in dn if d not in SKIP_DIRS]
        for f in fn:
            p = os.path.join(dp, f)[2:]
            if TEST_RE.search(p) and p.endswith(CODE_EXT):
                files.append(p)
    return files


def main():
    argv = sys.argv[1:]
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(2)
    spec, tests, base, all_tests, as_json = argv[0], [], None, False, False
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == "--tests":
            i += 1
            while i < len(argv) and not argv[i].startswith("--"):
                tests.append(argv[i]); i += 1
            continue
        if a == "--base":
            base = argv[i + 1]; i += 2; continue
        if a == "--all-tests":
            all_tests = True
        elif a == "--json":
            as_json = True
        i += 1
    spec_path, acs = parse_spec(spec)
    if not acs:
        print(f"ac_trace: no AC-n ids found in {spec_path}", file=sys.stderr)
        sys.exit(2)
    files = list_tests(tests, base or default_base(), all_tests)
    found = {ac: [] for ac in acs}
    for f in files:
        try:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                content = fh.read()
        except OSError:
            continue
        for ac in acs:
            if re.search(re.escape(ac) + r"(?!\d)", content):
                found[ac].append(f)
    missing = [ac for ac, fs in found.items() if not fs]
    missing_e2e = [ac for ac, e2e in acs.items() if e2e and found[ac] and not any(E2E_RE.search(f) for f in found[ac])]
    if as_json:
        print(json.dumps({"spec": spec_path, "covered": found, "missing": missing, "missing_e2e": missing_e2e}, indent=2))
    else:
        print(f"AC traceability — {spec_path} ({len(files)} test files scanned)")
        for ac in sorted(acs, key=lambda a: int(a.split('-')[1])):
            mark = "OK " if found[ac] and ac not in missing_e2e else "GAP"
            where = ", ".join(sorted(set(found[ac]))[:3]) or "-"
            print(f"  {mark} {ac}{' (E2E)' if acs[ac] else ''}: {where}")
        if missing:
            print(f"Uncovered: {', '.join(missing)}")
        if missing_e2e:
            print(f"Marked (E2E) but no E2E test references them: {', '.join(missing_e2e)}")
    sys.exit(1 if missing or missing_e2e else 0)


if __name__ == "__main__":
    main()
