#!/usr/bin/env python3
"""Parse a shell command line and report the git commit / push invocations in it.

Used by the agentic-sdd Bash hooks. Prints one line per invocation:
    COMMIT <dir> <no_verify:0|1>
    PUSH <force:0|1> <no_verify:0|1>
<dir> is the directory passed with `git -C <dir>` (or "." when absent).
Exit 0 always; prints nothing for commands that don't commit or push.
"""
import shlex
import sys

SEPARATORS = {"&&", "||", ";", "|", "&", "\n", "(", ")", ";;"}
# Short options of `git commit` that take a value (the rest of the cluster or the next token).
COMMIT_VALUE_OPTS = set("mFCcStu")
GLOBAL_VALUE_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}


def split_commands(cmd):
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=";&|()\n")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    lex.commenters = ""
    current = []
    for tok in lex:
        if tok in SEPARATORS or set(tok) <= set(";&|()\n"):
            if current:
                yield current
            current = []
        else:
            current.append(tok)
    if current:
        yield current


def parse_commit(args):
    no_verify = False
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            break
        if a == "--no-verify":
            no_verify = True
        elif a.startswith("--"):
            if "=" not in a and a in ("--message", "--file", "--reuse-message", "--reedit-message",
                                       "--fixup", "--squash", "--author", "--date", "--template",
                                       "--cleanup", "--trailer", "--pathspec-from-file"):
                i += 1
        elif a.startswith("-") and len(a) > 1:
            cluster = a[1:]
            for j, ch in enumerate(cluster):
                if ch == "n":
                    no_verify = True
                if ch in COMMIT_VALUE_OPTS:
                    if j == len(cluster) - 1:
                        i += 1  # value is the next token
                    break
        i += 1
    return no_verify


def parse_push(args):
    force = no_verify = False
    for a in args:
        if a in ("--force", "--force-with-lease", "--force-if-includes", "--mirror") or a.startswith("--force-with-lease="):
            force = True
        elif a == "--no-verify":
            no_verify = True
        elif a.startswith("-") and not a.startswith("--") and "f" in a[1:]:
            force = True
        elif a.startswith("+") and len(a) > 1:
            force = True  # +refspec force-pushes that ref
    return force, no_verify


def main():
    if len(sys.argv) < 2:
        return
    try:
        commands = list(split_commands(sys.argv[1]))
    except ValueError:
        return
    base = None  # directory from a preceding `cd <dir>` in the same command line
    for toks in commands:
        if len(toks) >= 2 and toks[0] == "cd":
            base = toks[1] if base is None or toks[1].startswith("/") else base.rstrip("/") + "/" + toks[1]
            continue
        # Drop leading env assignments and wrappers like `sudo`, `command`, `env`.
        while toks and ("=" in toks[0] and not toks[0].startswith("-") or toks[0] in ("sudo", "command", "env", "time", "nohup")):
            toks = toks[1:]
        if not toks or toks[0].rsplit("/", 1)[-1] != "git":
            continue
        i, cwd = 1, "."
        while i < len(toks) and toks[i].startswith("-"):
            opt = toks[i]
            if opt in GLOBAL_VALUE_OPTS:
                if opt == "-C" and i + 1 < len(toks):
                    cwd = toks[i + 1]
                i += 2
            else:
                i += 1
        if i >= len(toks):
            continue
        sub, rest = toks[i], toks[i + 1:]
        if base is not None and not cwd.startswith("/"):
            cwd = base if cwd == "." else base.rstrip("/") + "/" + cwd
        if sub == "commit":
            print(f"COMMIT {shlex.quote(cwd)} {int(parse_commit(rest))}")
        elif sub == "push":
            force, nv = parse_push(rest)
            print(f"PUSH {int(force)} {int(nv)}")


if __name__ == "__main__":
    main()
