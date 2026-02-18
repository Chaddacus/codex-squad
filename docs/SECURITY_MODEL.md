# Security Model

## Assets

- User Codex config files under `~/.codex`
- User workflow and policies in `~/.codex/AGENTS.md`

## Trust Boundaries

- Source repository files
- Local filesystem under `~/.codex`

## Controls

- Installer writes only to `~/.codex`
- Managed sections are marker-delimited and idempotent
- Existing files are backed up before modification
- No network calls in installer/doctor/uninstall
- No secrets in templates

## Non-Goals

- Runtime policy enforcement in Codex engine internals
- Hard sandboxing beyond Codex runtime controls
