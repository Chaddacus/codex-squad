# codex-squad

Portable multi-agent routing and role configuration for Codex.

This package gives Codex a Claude-style team workflow:
- automatic routing (`solo`, `pair`, `squad`, `full`, `explore`)
- planner-first task graph with dependency gates
- worker/reviewer/explorer role profiles
- idempotent installer with local backup

## What gets installed

- `~/.codex/agents/squad_planner.toml`
- `~/.codex/agents/squad_worker.toml`
- `~/.codex/agents/squad_reviewer.toml`
- `~/.codex/agents/squad_explorer.toml`
- A managed block in `~/.codex/config.toml`
- Upserted global keys in `~/.codex/config.toml`:
  - `features.multi_agent = true`
  - `agents.max_threads = 7`
- A managed router block in `~/.codex/AGENTS.md`

Installer markers:
- `# BEGIN CODEX-SQUAD` / `# END CODEX-SQUAD` in `config.toml`
- `<!-- BEGIN CODEX-SQUAD ROUTER -->` / `<!-- END CODEX-SQUAD ROUTER -->` in `AGENTS.md`

## Install

```bash
git clone https://github.com/Chaddacus/codex-squad.git
cd codex-squad
bash ./scripts/install.sh
```

## Verify

```bash
bash ./scripts/doctor.sh
```

## Security Sweep

```bash
bash ./scripts/security-sweep.sh
```

## Uninstall

```bash
bash ./scripts/uninstall.sh
```

This removes only CODEX-SQUAD managed blocks/files and keeps your other Codex config untouched.
It does not automatically revert shared global keys like `features.multi_agent` and `agents.max_threads`.

## Threat Model (short)

- Scope: local configuration files under `~/.codex`
- No network calls from install/doctor/uninstall scripts
- No token handling
- No destructive operations outside CODEX-SQUAD-managed assets

See `docs/SECURITY_MODEL.md` and `SECURITY.md`.

## License

MIT - see `LICENSE`.
