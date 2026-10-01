#!/usr/bin/env python3
"""Parse a shell command line and report the git commit / push invocations in it.

Used by the agentic-sdd Bash hooks. Prints one TAB-separated line per invocation, the
directory last (it may contain spaces):
    COMMIT <no_verify> <all> <pathspec> <add_before> <dir>
    PUSH   <force> <no_verify>
Flags are 0/1. <all> = -a/--all; <pathspec> = files named on the command line, -i or -o;
<add_before> = a `git add` ran earlier in the same command line (so the index the hook sees
is not what will be committed). <dir> is resolved from `cd` and `git -C` (~ and $VARS
expanded) against argv[2] (the hook's cwd) when given; "." when unknown.
Exit 0 on success, 3 when the command can't be parsed (caller falls back to a regex).
"""
import os
import shlex
import sys

OPS = set(";&|()\n")
# Short options of `git commit` whose value is mandatory (rest of the cluster or next token).
COMMIT_VALUE_OPTS = set("mFCct")
COMMIT_LONG_VALUE = {"--message", "--file", "--reuse-message", "--reedit-message", "--fixup", "--squash",
                     "--author", "--date", "--template", "--cleanup", "--trailer", "--pathspec-from-file"}
GLOBAL_VALUE_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
WRAPPERS = {"sudo", "command", "env", "time", "nohup", "exec"}
SHELLS = {"bash", "sh", "zsh"}


def split_commands(cmd):
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=";&|()\n")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    lex.commenters = ""
    current = []
    for tok in lex:
        if tok and set(tok) <= OPS:
            if current:
                yield current
            current = []
        else:
            current.append(tok)
    if current:
        yield current


def is_no_verify(a):
    return a.startswith("--no-veri") and "--no-verify".startswith(a)


def parse_commit(args):
    nv = all_ = pathspec = False
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            pathspec = pathspec or i + 1 < len(args)
            break
        if is_no_verify(a):
            nv = True
        elif a in ("--all",):
            all_ = True
        elif a in ("--include", "--only"):
            pathspec = True
        elif a.startswith("--"):
            if "=" not in a and a in COMMIT_LONG_VALUE:
                i += 1
        elif a.startswith("-") and len(a) > 1:
            cluster = a[1:]
            for j, ch in enumerate(cluster):
                if ch == "n":
                    nv = True
                elif ch == "a":
                    all_ = True
                elif ch in "io":
                    pathspec = True
                if ch in COMMIT_VALUE_OPTS:
                    if j == len(cluster) - 1:
                        i += 1
                    break
                if ch in "Su":  # optional value, only ever attached (-S<key>, -u<mode>)
                    break
        else:
            pathspec = True  # a bare argument is a pathspec
        i += 1
    return nv, all_, pathspec


def parse_push(args):
    force = nv = False
    for a in args:
        if a in ("--force", "--force-with-lease", "--force-if-includes", "--mirror") or a.startswith("--force-with-lease="):
            force = True
        elif is_no_verify(a):
            nv = True
        elif a.startswith("-") and not a.startswith("--") and "f" in a[1:]:
            force = True
        elif a.startswith("+") and len(a) > 1:
            force = True
    return force, nv


def resolve(base, d):
    d = os.path.expandvars(os.path.expanduser(d))
    if os.path.isabs(d):
        return os.path.normpath(d)
    return os.path.normpath(os.path.join(base, d)) if base else d


def scan(cmd, base, out, depth=0):
    add_seen = False
    for toks in split_commands(cmd):
        while toks and (("=" in toks[0] and not toks[0].startswith("-")) or toks[0] in WRAPPERS):
            toks = toks[1:]
        if not toks:
            continue
        prog = toks[0].rsplit("/", 1)[-1]
        if prog == "cd" and len(toks) >= 2:
            base = resolve(base, toks[1])
            continue
        if prog in SHELLS and depth < 2:
            for k, t in enumerate(toks[1:], 1):
                if t == "-c" and k + 1 < len(toks):
                    scan(toks[k + 1], base, out, depth + 1)
                    break
            continue
        if prog != "git":
            continue
        i, cwd = 1, base
        while i < len(toks) and toks[i].startswith("-"):
            opt = toks[i]
            if opt in GLOBAL_VALUE_OPTS:
                if opt == "-C" and i + 1 < len(toks):
                    cwd = resolve(cwd, toks[i + 1])
                i += 2
            else:
                i += 1
        if i >= len(toks):
            continue
        sub, rest = toks[i], toks[i + 1:]
        if sub in ("add", "rm", "mv", "stage"):
            add_seen = True
        elif sub == "commit":
            nv, all_, ps = parse_commit(rest)
            out.append("\t".join(["COMMIT", str(int(nv)), str(int(all_)), str(int(ps)), str(int(add_seen)), cwd or "."]))
        elif sub == "push":
            force, nv = parse_push(rest)
            out.append("\t".join(["PUSH", str(int(force)), str(int(nv))]))


def main():
    if len(sys.argv) < 2:
        return 0
    base = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None
    out = []
    try:
        scan(sys.argv[1], base, out)
    except ValueError:
        return 3
    if out:
        print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
