#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[OK] $1"
}

[[ "$CODEX_HOME" = /* ]] || fail "CODEX_HOME must be an absolute path"
[[ "$CODEX_HOME" != "/" ]] || fail "Refusing CODEX_HOME=/"

[[ -f "$CODEX_HOME/config.toml" ]] || fail "Missing $CODEX_HOME/config.toml"
[[ -f "$CODEX_HOME/AGENTS.md" ]] || fail "Missing $CODEX_HOME/AGENTS.md"

for f in squad_planner.toml squad_worker.toml squad_reviewer.toml squad_explorer.toml; do
  [[ -f "$CODEX_HOME/agents/$f" ]] || fail "Missing $CODEX_HOME/agents/$f"
done
pass "Required files exist"

grep -q '^# BEGIN CODEX-SQUAD$' "$CODEX_HOME/config.toml" || fail "Missing config begin marker"
grep -q '^# END CODEX-SQUAD$' "$CODEX_HOME/config.toml" || fail "Missing config end marker"
grep -q '^<!-- BEGIN CODEX-SQUAD ROUTER -->$' "$CODEX_HOME/AGENTS.md" || fail "Missing AGENTS begin marker"
grep -q '^<!-- END CODEX-SQUAD ROUTER -->$' "$CODEX_HOME/AGENTS.md" || fail "Missing AGENTS end marker"
pass "Managed markers are present"

if command -v python3 >/dev/null 2>&1; then
  python3 - "$CODEX_HOME" <<'PY'
import sys
from pathlib import Path

codex_home = Path(sys.argv[1])

try:
    import tomllib  # py311+
except ModuleNotFoundError:
    import tomli as tomllib  # type: ignore

files = [
    codex_home / "config.toml",
    codex_home / "agents" / "squad_planner.toml",
    codex_home / "agents" / "squad_worker.toml",
    codex_home / "agents" / "squad_reviewer.toml",
    codex_home / "agents" / "squad_explorer.toml",
]

for p in files:
    with p.open("rb") as f:
        data = tomllib.load(f)
        if p.name == "config.toml":
            features = data.get("features", {})
            agents = data.get("agents", {})
            if features.get("multi_agent") is not True:
                raise SystemExit("[FAIL] features.multi_agent must be true")
            if agents.get("max_threads") != 7:
                raise SystemExit("[FAIL] agents.max_threads must be 7")

print("[OK] TOML parse")
PY
else
  echo "[WARN] python3 not found; skipping TOML parse"
fi

pass "Doctor checks passed"
