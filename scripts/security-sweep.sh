#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "[1/5] shell syntax"
for f in scripts/*.sh; do
  bash -n "$f"
done

echo "[2/5] dangerous hardcoded paths"
if rg -n '/Users/chadsimon|/home/' README.md docs templates agents scripts \
  --glob '!scripts/security-sweep.sh' >/dev/null; then
  echo "[FAIL] Found machine-specific path"
  rg -n '/Users/chadsimon|/home/' README.md docs templates agents scripts \
    --glob '!scripts/security-sweep.sh'
  exit 1
fi

echo "[3/5] obvious secret patterns"
if rg -n '(ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)' . >/dev/null; then
  echo "[FAIL] Found potential secret material"
  rg -n '(ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)' .
  exit 1
fi

echo "[4/5] executable file policy"
for f in $(find . -type f ! -path './.git/*'); do
  if [[ -x "$f" && "$f" != scripts/* && "$f" != ./scripts/* ]]; then
    echo "[FAIL] Non-script file is executable: $f"
    exit 1
  fi
done

echo "[5/5] install + doctor dry run"
TMP_CODEX_HOME="$(mktemp -d)"

cat > "$TMP_CODEX_HOME/config.toml" <<'BASECFG'
[features]
multi_agent = false

[agents]
max_threads = 2

[agents.custom_agent]
description = "preexisting"
config_file = "agents/custom_agent.toml"
BASECFG

cat > "$TMP_CODEX_HOME/AGENTS.md" <<'BASEAGENTS'
# Existing AGENTS
Keep this content.
BASEAGENTS

CODEX_HOME="$TMP_CODEX_HOME" bash ./scripts/install.sh
CODEX_HOME="$TMP_CODEX_HOME" bash ./scripts/doctor.sh
CODEX_HOME="$TMP_CODEX_HOME" bash ./scripts/install.sh
CODEX_HOME="$TMP_CODEX_HOME" bash ./scripts/doctor.sh

CODEX_HOME="$TMP_CODEX_HOME" bash ./scripts/uninstall.sh
if grep -q 'BEGIN CODEX-SQUAD' "$TMP_CODEX_HOME/config.toml"; then
  echo "[FAIL] uninstall left managed config block"
  exit 1
fi
if grep -q 'BEGIN CODEX-SQUAD ROUTER' "$TMP_CODEX_HOME/AGENTS.md"; then
  echo "[FAIL] uninstall left managed AGENTS block"
  exit 1
fi

rm -rf "$TMP_CODEX_HOME"

echo "[OK] Security sweep passed"
