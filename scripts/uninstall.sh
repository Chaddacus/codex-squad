#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

[[ "$CODEX_HOME" = /* ]] || { echo "CODEX_HOME must be an absolute path" >&2; exit 1; }
[[ "$CODEX_HOME" != "/" ]] || { echo "Refusing CODEX_HOME=/" >&2; exit 1; }

strip_managed_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  awk -v b="$begin" -v e="$end" '
    $0 ~ b {skip=1; next}
    $0 ~ e {skip=0; next}
    skip==0 {print}
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

strip_managed_block "$CODEX_HOME/config.toml" '^# BEGIN CODEX-SQUAD$' '^# END CODEX-SQUAD$'
strip_managed_block "$CODEX_HOME/AGENTS.md" '^<!-- BEGIN CODEX-SQUAD ROUTER -->$' '^<!-- END CODEX-SQUAD ROUTER -->$'

rm -f "$CODEX_HOME/agents/squad_planner.toml"
rm -f "$CODEX_HOME/agents/squad_worker.toml"
rm -f "$CODEX_HOME/agents/squad_reviewer.toml"
rm -f "$CODEX_HOME/agents/squad_explorer.toml"

echo "Uninstall complete."
