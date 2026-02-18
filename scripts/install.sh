#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BACKUP_ROOT="$CODEX_HOME/backups/codex-squad"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TS"

[[ "$CODEX_HOME" = /* ]] || { echo "CODEX_HOME must be an absolute path" >&2; exit 1; }
[[ "$CODEX_HOME" != "/" ]] || { echo "Refusing to use CODEX_HOME=/" >&2; exit 1; }

mkdir -p "$CODEX_HOME" "$CODEX_HOME/agents" "$BACKUP_DIR"

backup_if_exists() {
  local f="$1"
  if [[ -f "$f" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${f#$CODEX_HOME/}")"
    cp "$f" "$BACKUP_DIR/${f#$CODEX_HOME/}"
  fi
}

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

append_file() {
  local target="$1"
  local source="$2"
  if [[ -f "$target" ]] && [[ -s "$target" ]]; then
    printf "\n" >> "$target"
  fi
  cat "$source" >> "$target"
  printf "\n" >> "$target"
}

upsert_toml_key() {
  local file="$1"
  local table="$2"
  local key="$3"
  local value="$4"

  if grep -q "^\\[$table\\]$" "$file"; then
    awk -v table="$table" -v key="$key" -v value="$value" '
      BEGIN {in_table=0; done=0}
      {
        if ($0 ~ "^\\[") {
          if (in_table && !done) {
            print key " = " value
            done=1
          }
          in_table = ($0 == "[" table "]")
        }

        if (in_table && $0 ~ ("^" key "[[:space:]]*=")) {
          if (!done) {
            print key " = " value
            done=1
          }
          next
        }

        print
      }
      END {
        if (in_table && !done) {
          print key " = " value
        }
      }
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  else
    {
      printf "\n[%s]\n" "$table"
      printf "%s = %s\n" "$key" "$value"
    } >> "$file"
  fi
}

backup_if_exists "$CODEX_HOME/config.toml"
backup_if_exists "$CODEX_HOME/AGENTS.md"
backup_if_exists "$CODEX_HOME/agents/squad_planner.toml"
backup_if_exists "$CODEX_HOME/agents/squad_worker.toml"
backup_if_exists "$CODEX_HOME/agents/squad_reviewer.toml"
backup_if_exists "$CODEX_HOME/agents/squad_explorer.toml"

cp "$REPO_ROOT/agents/squad_planner.toml" "$CODEX_HOME/agents/squad_planner.toml"
cp "$REPO_ROOT/agents/squad_worker.toml" "$CODEX_HOME/agents/squad_worker.toml"
cp "$REPO_ROOT/agents/squad_reviewer.toml" "$CODEX_HOME/agents/squad_reviewer.toml"
cp "$REPO_ROOT/agents/squad_explorer.toml" "$CODEX_HOME/agents/squad_explorer.toml"

if [[ ! -f "$CODEX_HOME/config.toml" ]]; then
  : > "$CODEX_HOME/config.toml"
fi

upsert_toml_key "$CODEX_HOME/config.toml" "features" "multi_agent" "true"
upsert_toml_key "$CODEX_HOME/config.toml" "agents" "max_threads" "7"
strip_managed_block "$CODEX_HOME/config.toml" '^# BEGIN CODEX-SQUAD$' '^# END CODEX-SQUAD$'
append_file "$CODEX_HOME/config.toml" "$REPO_ROOT/templates/config.block.toml"

if [[ ! -f "$CODEX_HOME/AGENTS.md" ]]; then
  cat > "$CODEX_HOME/AGENTS.md" <<'BASE'
# Global AGENTS

Project-level AGENTS.md files take precedence over this file.
BASE
fi
strip_managed_block "$CODEX_HOME/AGENTS.md" '^<!-- BEGIN CODEX-SQUAD ROUTER -->$' '^<!-- END CODEX-SQUAD ROUTER -->$'
append_file "$CODEX_HOME/AGENTS.md" "$REPO_ROOT/templates/AGENTS.router.md"

echo "Install complete."
echo "Backup: $BACKUP_DIR"
echo "Run ./scripts/doctor.sh to verify."
