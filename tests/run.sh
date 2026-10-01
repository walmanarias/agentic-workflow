#!/usr/bin/env bash
# Behavioral tests for the agentic-sdd hooks and tools — no dependencies beyond bash,
# git, python3 and jq/python for JSON. Run: bash tests/run.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
S="$REPO/plugins/agentic-sdd/hooks/scripts"
T="$REPO/plugins/agentic-sdd/tools"
PASS=0; FAILN=0; FAILED=()
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
export AGENTIC_SDD_LANG=en GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

ok()   { PASS=$((PASS+1)); }
bad()  { FAILN=$((FAILN+1)); FAILED+=("$1"); printf '  FAIL %s\n' "$1"; }
# expect <name> <expected-exit> <cmd...>
expect() {
  local name="$1" want="$2"; shift 2
  local out; out="$("$@" 2>&1)"; local got=$?
  if [ "$got" = "$want" ]; then ok; else bad "$name (want exit $want, got $got) :: ${out:0:300}"; fi
}
json() { python3 -c 'import json,sys; print(json.dumps(json.loads(sys.argv[1])))' "$1"; }
hook() { local script="$1" payload="$2"; printf '%s' "$payload" | CLAUDE_PROJECT_DIR="${PROJ:-$WORK}" bash "$S/$script"; }
edit_payload() { python3 -c 'import json,sys; d={"tool_name":"Edit","tool_input":{"file_path":sys.argv[1],"new_string":sys.argv[2]}}
if len(sys.argv)>3 and sys.argv[3]: d["agent_type"]=sys.argv[3]
print(json.dumps(d))' "$@"; }
bash_payload() { python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"; }

echo "guard-edits"
expect "blocks .only in a test"            2 hook guard-edits.sh "$(edit_payload "$WORK/src/a.test.ts" "it.only('x', () => {})")"
expect "blocks it.skip in a test"          2 hook guard-edits.sh "$(edit_payload "$WORK/src/a.test.ts" "it.skip('x', () => {})")"
expect "blocks xit in a test"              2 hook guard-edits.sh "$(edit_payload "$WORK/src/a.spec.tsx" "  xit('x', () => {})")"
expect "blocks test.todo in a test"        2 hook guard-edits.sh "$(edit_payload "$WORK/src/a.test.js" "test.todo('later')")"
expect "allows sdd-allow-skip"             0 hook guard-edits.sh "$(edit_payload "$WORK/src/a.test.ts" "it.skip('mac only', () => {}) // sdd-allow-skip: needs macOS")"
expect "allows .skip outside tests"        0 hook guard-edits.sh "$(edit_payload "$WORK/src/list.ts" "const rest = list.skip(1)")"
expect "blocks pytest skip"                2 hook guard-edits.sh "$(edit_payload "$WORK/tests/test_a.py" "@pytest.mark.skip(reason='x')")"
expect "blocks pytest xfail"               2 hook guard-edits.sh "$(edit_payload "$WORK/tests/test_a.py" "@pytest.mark.xfail")"
expect "blocks xunit Skip="                2 hook guard-edits.sh "$(edit_payload "$WORK/App.Tests/FooTests.cs" '[Fact(Skip = "flaky")]')"
expect "blocks debugger"                   2 hook guard-edits.sh "$(edit_payload "$WORK/src/a.ts" "debugger;")"
expect "allows clean edit"                 0 hook guard-edits.sh "$(edit_payload "$WORK/src/a.ts" "export const x = 1;")"
expect "blocks legacy MultiEdit edits[]"   2 hook guard-edits.sh "$(json '{"tool_name":"MultiEdit","tool_input":{"file_path":"'"$WORK"'/a.test.ts","edits":[{"old_string":"a","new_string":"describe.skip(\"x\", () => {})"}]}}')"

echo "role-guard"
expect "main thread unrestricted"          0 hook role-guard.sh "$(edit_payload "$WORK/src/a.test.ts" "x")"
expect "test-writer may write tests"       0 hook role-guard.sh "$(edit_payload "$WORK/src/a.test.ts" "x" tdd-test-writer)"
expect "test-writer blocked on src"        2 hook role-guard.sh "$(edit_payload "$WORK/src/a.ts" "x" tdd-test-writer)"
expect "implementer blocked on tests"      2 hook role-guard.sh "$(edit_payload "$WORK/src/a.test.ts" "x" implementer)"
expect "namespaced implementer blocked"    2 hook role-guard.sh "$(edit_payload "$WORK/tests/test_a.py" "x" agentic-sdd:implementer)"
expect "implementer may write src"         0 hook role-guard.sh "$(edit_payload "$WORK/src/a.ts" "x" agentic-sdd:implementer)"
expect "other plugin's implementer free"   0 hook role-guard.sh "$(edit_payload "$WORK/src/a.test.ts" "x" other:implementer)"
expect "spec-writer only specs/"           2 hook role-guard.sh "$(edit_payload "$WORK/src/a.ts" "x" spec-writer)"
expect "spec-writer in specs/"             0 hook role-guard.sh "$(edit_payload "$WORK/specs/login/spec.md" "x" spec-writer)"
expect "planner in specs/"                 0 hook role-guard.sh "$(edit_payload "$WORK/specs/login/plan.md" "x" planner)"
expect "curator blocked on src"            2 hook role-guard.sh "$(edit_payload "$WORK/src/a.ts" "x" curator)"
expect "curator writes 9x rule"            0 hook role-guard.sh "$(edit_payload "$WORK/.claude/rules/90-api.md" "x" curator)"
expect "reviewer writes review.md"         0 hook role-guard.sh "$(edit_payload "$WORK/specs/login/review.md" "x" code-reviewer)"
expect "role guard can be turned off"      0 env AGENTIC_SDD_ROLE_GUARD=off bash -c "printf '%s' '$(edit_payload "$WORK/src/a.ts" "x" tdd-test-writer)' | bash '$S/role-guard.sh'"

echo "bash-guard"
expect "blocks commit --no-verify"         2 hook bash-guard.sh "$(bash_payload 'git commit --no-verify -m x')"
expect "blocks commit -nm"                 2 hook bash-guard.sh "$(bash_payload 'git commit -nm x')"
expect "blocks git -C dir commit -n"       2 hook bash-guard.sh "$(bash_payload 'git -C sub commit -n -m x')"
expect "allows -n inside message"          0 hook bash-guard.sh "$(bash_payload 'git commit -m "use -n flag"')"
expect "blocks push --force"               2 hook bash-guard.sh "$(bash_payload 'git push --force')"
expect "blocks push -f"                    2 hook bash-guard.sh "$(bash_payload 'git push -f origin feat')"
expect "blocks --force-with-lease"         2 hook bash-guard.sh "$(bash_payload 'git push --force-with-lease origin feat')"
expect "blocks +refspec"                   2 hook bash-guard.sh "$(bash_payload 'git push origin +main')"
expect "allows normal push"                0 hook bash-guard.sh "$(bash_payload 'git push -u origin HEAD')"
expect "ignores non-git"                   0 hook bash-guard.sh "$(bash_payload 'echo git commit --no-verify')"

echo "pre-commit-gate"
R="$WORK/repo"; mkdir -p "$R/src" "$R/tests"; git -C "$R" init -q
printf 'export const a = 1;\n' > "$R/src/a.ts"
printf "test('AC-1 adds', () => { expect(1).toBe(1); expect(2).toBe(2); });\n" > "$R/src/a.test.ts"
git -C "$R" add -A && git -C "$R" commit -qm init --no-verify
gate() { PROJ="$R" hook pre-commit-gate.sh "$(bash_payload "$1")"; }
printf 'export const b = 2;\n' > "$R/src/b.ts"; git -C "$R" add src/b.ts
expect "clean commit passes"               0 gate 'git commit -m "feat: b"'
git -C "$R" commit -qm b --no-verify
printf "test.skip('AC-2', () => {});\n" >> "$R/src/a.test.ts"; git -C "$R" add -A
expect "skip in staged test blocks"        2 gate 'git commit -m "test: skip"'
git -C "$R" checkout -q -- . 2>/dev/null; git -C "$R" reset -q --hard
printf "test('AC-1 adds', () => { expect(1).toBe(1); });\n" > "$R/src/a.test.ts"; git -C "$R" add -A
expect "removed assertion blocks"          2 gate 'git commit -m "test: trim"'
expect "Test-Change trailer allows it"     0 gate 'git commit -m "test: trim" -m "Test-Change: duplicate assertion"'
git -C "$R" reset -q --hard
git -C "$R" rm -q src/a.test.ts
expect "deleted test file blocks"          2 gate 'git commit -m "chore: rm"'
git -C "$R" reset -q --hard
printf 'const k = "AKIAABCDEFGHIJKLMNOP";\n' > "$R/src/k.ts"; git -C "$R" add -A  # sdd-allow-secret: test fixture
expect "secret blocks"                     2 gate 'git commit -m "feat: k"'
git -C "$R" reset -q --hard; rm -f "$R/src/k.ts"
printf 'debugger;\n' > "$R/src/d.ts"; git -C "$R" add -A
expect "debugger blocks"                   2 gate 'git commit -m "feat: d"'
expect "git -C path detected"              2 bash -c "cd '$WORK' && printf '%s' '$(bash_payload "git -C repo commit -m x")' | CLAUDE_PROJECT_DIR='$WORK' bash '$S/pre-commit-gate.sh'"
expect "commit-tree is not a commit"       0 gate 'git commit-tree HEAD^{tree} -m x'
git -C "$R" reset -q --hard; rm -f "$R/src/d.ts"

echo "pre-commit-gate: regressions from the adversarial review"
gate_in() { local dir="$1" c="$2"; python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[2],"tool_input":{"command":sys.argv[1]}}))' "$c" "$dir" | CLAUDE_PROJECT_DIR="$dir" bash "$S/pre-commit-gate.sh"; }
printf 'debugger;\n' > "$R/src/d.ts"
expect "add && commit sees unstaged debugger"  2 gate 'git add -A && git commit -m "feat: d"'
rm -f "$R/src/d.ts"; printf 'debugger;\n' >> "$R/src/a.ts"
expect "pathspec commit sees unstaged change"  2 gate 'git commit -m "feat: d" src/a.ts'
expect "-m '-name' text isn't -a"              0 gate 'git commit -m "docs: the -name option"'
git -C "$R" checkout -q -- src/a.ts
SP="$WORK/My Proj"; mkdir -p "$SP"; git -C "$SP" init -q; printf 'debugger;\n' > "$SP/x.js"; git -C "$SP" add -A
expect "repo path with spaces is gated"        2 gate_in "$WORK" "cd \"$SP\" && git commit -m x"
expect "git -C path with spaces is gated"      2 gate_in "$WORK" "git -C \"$SP\" commit -m x"
NA="$WORK/Diseño"; mkdir -p "$NA"; git -C "$NA" init -q; printf 'debugger;\n' > "$NA/x.js"; git -C "$NA" add -A
expect "non-ASCII repo path is gated"          2 gate_in "$WORK" "cd \"$NA\" && git commit -m x"
mkdir -p "$R/app"
printf 'users = User.objects.only("id")\n' > "$R/app/q.py"
printf '@include breakpoint(medium);\n' > "$R/src/s.scss"
mkdir -p "$R/specs/login"; printf 'Found an `it.only(` left in a test.\n' > "$R/specs/login/review.md"
git -C "$R" add -A
expect "no focus false positives (py/scss/md)" 0 gate 'git commit -m "feat: q"'
git -C "$R" commit -qm q --no-verify
printf "const k = 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789';\n" > "$R/src/ak.ts"; git -C "$R" add -A  # sdd-allow-secret: test fixture
expect "modern sk-ant key detected"            2 gate 'git commit -m "feat: ak"'
printf "const k = 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789'; // sdd-allow-secret: fake key for a fixture\n" > "$R/src/ak.ts"; git -C "$R" add -A
expect "sdd-allow-secret exempts a line"       0 gate 'git commit -m "feat: ak"'
printf "const u = 'https://x/task-0123456789abcdef0123456789abcdef01234567';\n" > "$R/src/ak.ts"; git -C "$R" add -A
expect "no secret false positive on task-<hex>" 0 gate 'git commit -m "feat: ak"'
git -C "$R" reset -q --hard; rm -f "$R/src/ak.ts"
printf "test.skip('x', () => {});\n" > "$R/src/café.test.ts"; git -C "$R" add -A
expect "non-ASCII test filename still checked" 2 gate 'git commit -m "test: c"'
git -C "$R" reset -q --hard; rm -f "$R/src/café.test.ts"
printf '{"name":"v","scripts":{}}\n' > "$R/package.json"; printf '<template><p/></template>\n' > "$R/src/C.vue"; git -C "$R" add -A
expect ".vue-only commit doesn't crash"        0 gate 'git commit -m "feat: vue"'
git -C "$R" commit -qm vue --no-verify
# Concluding a merge whose other side deliberately deleted a test is not "weakening".
git -C "$R" checkout -qb side; git -C "$R" rm -q src/a.test.ts; git -C "$R" commit -qm "rm" --no-verify
git -C "$R" checkout -q -; git -C "$R" checkout -qb feat2; printf 'x\n' > "$R/notes.txt"; git -C "$R" add -A; git -C "$R" commit -qm n --no-verify
git -C "$R" merge -q --no-commit --no-ff side >/dev/null 2>&1
expect "finishing a merge isn't blocked"       0 gate 'git commit -m "merge side"'
git -C "$R" merge --abort 2>/dev/null

echo "bash-guard: parser regressions"
expect "unbalanced quote falls back + blocks" 2 hook bash-guard.sh "$(bash_payload "git commit -n -F - <<'EOF'
it's done
EOF")"
expect "-S then -n"                            2 hook bash-guard.sh "$(bash_payload 'git commit -S -n -m x')"
expect "abbreviated --no-verif"                2 hook bash-guard.sh "$(bash_payload 'git commit --no-verif -m x')"
expect "bash -c wrapped commit"                2 hook bash-guard.sh "$(bash_payload 'bash -c "git commit -n -m x"')"
expect "cd into path with spaces + -n"         2 hook bash-guard.sh "$(bash_payload 'cd "/tmp/My Proj" && git commit --no-verify -m x')"

echo "role-guard: path classification"
expect "test-writer: MSW mocks"                0 hook role-guard.sh "$(edit_payload "$WORK/src/mocks/handlers.ts" "x" tdd-test-writer)"
expect "test-writer: vitest.setup.ts"          0 hook role-guard.sh "$(edit_payload "$WORK/vitest.setup.ts" "x" tdd-test-writer)"
expect "test-writer: setupTests.ts"            0 hook role-guard.sh "$(edit_payload "$WORK/src/setupTests.ts" "x" tdd-test-writer)"
expect "test-writer: test-utils"               0 hook role-guard.sh "$(edit_payload "$WORK/src/test-utils/render.tsx" "x" tdd-test-writer)"
expect "test-writer: .NET UnitTests project"   0 hook role-guard.sh "$(edit_payload "$WORK/MyApp.UnitTests/Fakes/FakeClock.cs" "x" tdd-test-writer)"
expect "test-writer: cypress support"          0 hook role-guard.sh "$(edit_payload "$WORK/cypress/support/commands.ts" "x" tdd-test-writer)"
expect "implementer: AbTest.cs is production"  0 hook role-guard.sh "$(edit_payload "$WORK/src/Experiments/AbTest.cs" "x" implementer)"
expect "implementer: openapi.spec.yaml"        0 hook role-guard.sh "$(edit_payload "$WORK/api/openapi.spec.yaml" "x" implementer)"
expect "implementer: src/e2e encryption"       0 hook role-guard.sh "$(edit_payload "$WORK/src/e2e/encryption.ts" "x" implementer)"
expect "implementer: Django fixtures"          0 hook role-guard.sh "$(edit_payload "$WORK/app/fixtures/initial_data.json" "x" implementer)"
expect "NotebookEdit path guarded"             2 hook role-guard.sh "$(json '{"tool_name":"NotebookEdit","agent_type":"tdd-test-writer","tool_input":{"notebook_path":"'"$WORK"'/analysis.ipynb"}}')"

echo "tools"
F="$WORK/ac"; mkdir -p "$F/specs/login" "$F/src" "$F/e2e"; git -C "$F" init -q
cat > "$F/specs/login/spec.md" <<'MD'
# Login
## Acceptance criteria
- **AC-1** — Given a user, When they log in, Then 200.
- **AC-2** — Given bad password, Then 401.
- **AC-10** — Given the form (E2E), Then it renders.
## Edge cases
- AC-99 mentioned outside the section is ignored
MD
printf "test('logs in (AC-1)', () => {});\ntest('rejects (AC-2)', () => {});\n" > "$F/src/login.test.ts"
expect "ac_trace finds the gap"            1 bash -c "cd '$F' && python3 '$T/ac_trace.py' specs/login --all-tests"
printf "test('renders form (AC-10)', () => {});\n" > "$F/e2e/login.e2e.ts"
expect "ac_trace all covered"              0 bash -c "cd '$F' && python3 '$T/ac_trace.py' specs/login --all-tests"
printf "test('renders form (AC-10)', () => {});\n" > "$F/src/form.test.ts"; rm "$F/e2e/login.e2e.ts"
expect "ac_trace E2E-marked needs e2e"     1 bash -c "cd '$F' && python3 '$T/ac_trace.py' specs/login --all-tests"
printf "test('renders form (AC-10)', () => {});\n" > "$F/e2e/login.e2e.ts"
printf -- '- ~~**AC-11**~~ retired in v2\n' >> "$F/specs/login/spec.md"
python3 - "$F/specs/login/spec.md" <<'PYX'
import sys; p=sys.argv[1]; s=open(p).read()
s=s.replace("## Acceptance criteria\n","## Acceptance criteria\n> Each is automatable. Mark (E2E). Never renumber — retire (~~AC-4~~ retired in v2).\n- ~~**AC-11**~~ retired in v2\n",1)
open(p,'w').write(s)
PYX
expect "ac_trace ignores retired/guidance"   0 bash -c "cd '$F' && python3 '$T/ac_trace.py' specs/login --all-tests"
cp "$F/specs/login/spec.md" "$F/specs/legacy.spec.md"
expect "ac_trace reads legacy layout"        0 bash -c "cd '$F' && python3 '$T/ac_trace.py' specs/legacy --all-tests"
expect "ac_trace missing spec = exit 2"      2 bash -c "cd '$F' && python3 '$T/ac_trace.py' specs/nope --all-tests"

C="$WORK/cov"; mkdir -p "$C/coverage" "$C/src"; git -C "$C" init -q
printf '{"total":{},"%s/src/a.ts":{"lines":{"total":10,"covered":9}},"%s/src/b.ts":{"lines":{"total":10,"covered":5}}}' "$C" "$C" > "$C/coverage/coverage-summary.json"
expect "coverage passes at 70"             0 bash -c "cd '$C' && python3 '$T/coverage_check.py' --threshold 70 --files src/a.ts src/b.ts"
expect "coverage fails at 80"              1 bash -c "cd '$C' && python3 '$T/coverage_check.py' --threshold 80 --files src/a.ts src/b.ts"
cat > "$C/coverage.xml" <<'XML'
<coverage><sources><source>.</source></sources><packages><package><classes>
<class filename="app/svc.py"><lines><line number="1" hits="1"/><line number="2" hits="0"/></lines></class>
</classes></package></packages></coverage>
XML
expect "cobertura report parsed"           1 bash -c "cd '$C' && python3 '$T/coverage_check.py' --threshold 80 --report coverage.xml --files app/svc.py"
mkdir -p "$C/r1" "$C/r2"
cob() { printf '<coverage><sources><source>.</source></sources><packages><package><classes><class filename="App/Foo.cs"><lines>%s</lines></class></classes></package></packages></coverage>' "$1"; }
L1=""; L2=""; for n in 1 2 3 4 5 6 7 8 9 10; do h1=0; h2=0; [ $n -le 8 ] && h1=1; { [ $n -le 3 ] || [ $n -eq 9 ] || [ $n -eq 10 ]; } && h2=1; L1="$L1<line number=\"$n\" hits=\"$h1\"/>"; L2="$L2<line number=\"$n\" hits=\"$h2\"/>"; done
cob "$L1" > "$C/r1/coverage.cobertura.xml"; cob "$L2" > "$C/r2/coverage.cobertura.xml"
expect "cobertura reports are merged (union)" 0 bash -c "cd '$C' && python3 '$T/coverage_check.py' --threshold 100 --report r1/coverage.cobertura.xml r2/coverage.cobertura.xml --files App/Foo.cs"
expect "no report = exit 2"                2 bash -c "cd '$WORK' && mkdir -p empty && cd empty && python3 '$T/coverage_check.py' --files x.ts"

D="$WORK/stack"; mkdir -p "$D/web" "$D/api"
printf '{"dependencies":{"next":"15","react":"19","react-dom":"19","pg":"8"},"devDependencies":{"vitest":"2"}}' > "$D/web/package.json"
printf '[project]\ndependencies = ["fastapi>=0.110", "sqlalchemy"]\n' > "$D/api/pyproject.toml"
out="$(python3 "$T/detect_stack.py" "$D")"
case "$out" in *react-expert*nextjs-expert*fastapi-expert*database-expert*vitest*) ok;; *) bad "detect_stack output: $out";; esac

echo "installer"
I="$WORK/install"; mkdir -p "$I"
expect "copy installer runs"               0 bash "$REPO/scripts/install.sh" "$I"
expect "no \${CLAUDE_PLUGIN_ROOT} left"    1 grep -rl 'CLAUDE_PLUGIN_ROOT' "$I/.claude/commands" "$I/.claude/agents" "$I/.claude/skills"
expect "tools copied"                      0 test -f "$I/.claude/tools/ac_trace.py"
printf '# Rule: curated\n' > "$I/.claude/rules/90-api.md"
bash "$REPO/scripts/install.sh" "$I" >/dev/null 2>&1
expect "re-install keeps curated 9x rules" 0 test -f "$I/.claude/rules/90-api.md"
if command -v jq >/dev/null 2>&1; then
  jq '.permissions.deny += ["Read(./prod.env)"] | .permissions.allow += ["Bash(make *)"]' "$I/.claude/settings.json" > "$I/s.tmp" && mv "$I/s.tmp" "$I/.claude/settings.json"
  bash "$REPO/scripts/install.sh" "$I" >/dev/null 2>&1
  expect "settings merge keeps user deny"   0 grep -q 'Read(./prod.env)' "$I/.claude/settings.json"
  expect "settings merge keeps user allow"  0 grep -q 'Bash(make \*)' "$I/.claude/settings.json"
  expect "settings merge has no dup hooks"  0 test "$(jq '.hooks.PreToolUse | length' "$I/.claude/settings.json")" = "2"
fi

echo
echo "passed: $PASS  failed: $FAILN"
[ "$FAILN" -eq 0 ]
