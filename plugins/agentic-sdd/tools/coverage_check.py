#!/usr/bin/env python3
"""Changed-files coverage gate — polyglot.

Usage: coverage_check.py [--threshold N] [--base REF] [--files F ...] [--report PATH ...]

Reads whatever coverage reports exist (auto-discovered unless --report is given):
  - Istanbul json-summary:  **/coverage/coverage-summary.json  (Jest/Vitest: coverageReporters ["json-summary"])
  - Cobertura XML:          **/coverage.cobertura.xml (coverlet / dotnet test --collect "XPlat Code Coverage")
                            **/coverage.xml           (pytest --cov --cov-report=xml)
Computes line coverage over the source files changed on this branch (vs the merge-base
with --base; test files excluded) and fails when it is below the threshold.
Threshold: --threshold, else $AGENTIC_SDD_COVERAGE, else 80.
Exit 0 = pass; 1 = below threshold; 2 = no report found (generate one first).
"""
import glob
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

SRC_EXT = (".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".mts", ".cts", ".py", ".cs")
TEST_RE = re.compile(r"(\.(test|spec|e2e)\.)|(/__tests__/)|(^|/)(e2e|tests?)/|(^|/)test_[^/]*\.py$|_test\.py$|conftest\.py$|\.Tests/|Tests?\.cs$|\.d\.ts$")
IGNORE_DIRS = ("node_modules/", "/bin/", "/obj/", ".venv/", "venv/", "dist/", "build/")


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


def norm(p):
    return p.replace("\\", "/").lstrip("./")


def load_reports(paths):
    """Return {path: (covered_lines, total_lines)} merged across reports."""
    data = {}
    for rp in paths:
        try:
            if rp.endswith(".json"):
                with open(rp, encoding="utf-8") as fh:
                    summary = json.load(fh)
                for path, stats in summary.items():
                    if path == "total":
                        continue
                    lines = stats.get("lines", {})
                    data[norm(path)] = (lines.get("covered", 0), lines.get("total", 0))
            else:
                root = ET.parse(rp).getroot()
                sources = [norm(s.text or "") for s in root.iter("source")]
                for cls in root.iter("class"):
                    fn = norm(cls.get("filename", ""))
                    lines = cls.find("lines")
                    if lines is None:
                        continue
                    hits = [int(l.get("hits", "0")) for l in lines.iter("line")]
                    cov, tot = sum(1 for h in hits if h > 0), len(hits)
                    keys = [fn] + [norm(os.path.join(s, fn)) for s in sources if s]
                    for k in keys:
                        c0, t0 = data.get(k, (0, 0))
                        data[k] = (c0 + cov, t0 + tot)
        except (OSError, ValueError, ET.ParseError):
            continue
    return data


def lookup(data, f):
    f = norm(f)
    best = None
    for k, v in data.items():
        if k == f or k.endswith("/" + f) or f.endswith("/" + k):
            if best is None or len(k) > len(best[0]):
                best = (k, v)
    return best[1] if best else None


def main():
    argv = sys.argv[1:]
    threshold = float(os.environ.get("AGENTIC_SDD_COVERAGE", "80"))
    base, files, reports = None, [], []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("-h", "--help"):
            print(__doc__); sys.exit(0)
        if a == "--threshold":
            threshold = float(argv[i + 1]); i += 2; continue
        if a == "--base":
            base = argv[i + 1]; i += 2; continue
        if a in ("--files", "--report"):
            target = files if a == "--files" else reports
            i += 1
            while i < len(argv) and not argv[i].startswith("--"):
                target.append(argv[i]); i += 1
            continue
        i += 1
    if not reports:
        reports = [p for pat in ("**/coverage/coverage-summary.json", "**/coverage.cobertura.xml", "**/coverage.xml")
                   for p in glob.glob(pat, recursive=True) if "node_modules" not in p]
    if not reports:
        print("coverage_check: no coverage report found. Generate one first (vitest/jest --coverage with the "
              "json-summary reporter, dotnet test --collect \"XPlat Code Coverage\", pytest --cov --cov-report=xml).",
              file=sys.stderr)
        sys.exit(2)
    if not files:
        b = base or default_base()
        mb = git("merge-base", b, "HEAD").strip() if b else ""
        files = git("diff", "--name-only", "--diff-filter=ACMR", mb or (b or "HEAD")).splitlines()
    files = [f for f in files if f.endswith(SRC_EXT) and not TEST_RE.search(f) and not any(d in f for d in IGNORE_DIRS)]
    if not files:
        print("coverage_check: no changed source files — nothing to measure.")
        sys.exit(0)
    data = load_reports(reports)
    covered = total = 0
    rows = []
    for f in sorted(files):
        hit = lookup(data, f)
        if hit is None:
            rows.append((f, None))
            continue
        c, t = hit
        covered += c; total += t
        rows.append((f, (100.0 * c / t) if t else 100.0))
    pct = (100.0 * covered / total) if total else 0.0
    print(f"Changed-files line coverage: {pct:.1f}% (threshold {threshold:g}%) from {len(reports)} report(s)")
    for f, p in rows:
        print(f"  {'  n/a' if p is None else f'{p:5.1f}'}%  {f}")
    missing = [f for f, p in rows if p is None]
    if missing:
        print(f"Warning — not in any report (excluded from coverage, or never executed by a test): {', '.join(missing)}")
    if not total:
        print("coverage_check: none of the changed files appear in the coverage report(s).", file=sys.stderr)
    sys.exit(0 if total and pct >= threshold else 1)


if __name__ == "__main__":
    main()
