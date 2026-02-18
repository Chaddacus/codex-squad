<!-- BEGIN CODEX-SQUAD ROUTER -->
## Automatic Agent Team Routing (Codex)

Default behavior for non-trivial coding work: decide team usage and team size automatically before implementation.

### Routing Pass (run first)

Evaluate:
- Estimated files touched
- Number of architectural layers affected (API, service, data, UI, infra)
- Parallelizable work streams
- Shared-file contention risk between streams
- Uncertainty (unclear root cause or unknown codebase areas)
- Risk (security, auth, migrations, production impact)

### Preset Selection

- **solo (0 agents):** <=2 files, one layer, low risk, clear fix path
- **pair (1 agent):** 3-5 files, up to 2 independent streams, moderate risk
- **squad (2-4 agents):** 6-12 files, 3+ independent streams, multi-layer feature work
- **full (5-7 agents):** >12 files, greenfield builds, major refactors, or migration-heavy work
- **explore (2-3 read-only agents):** root cause unknown, architecture decision unclear, or first pass in a large unfamiliar codebase
- If sizing confidence is low, start with **pair** and scale up after planner output confirms independent streams.

### Do Not Use Teams

- Task is mostly sequential and cannot be split into independent streams.
- Work centers on one shared file or tightly coupled adjacent code that would conflict.
- Change is docs-only or pure reading/research with no implementation.
- Project has no runnable validation path and no practical way to verify teammate outputs.

### Execution Protocol

1. **Planner first:** Create data flow, API contracts, acceptance criteria, dependency graph, and file ownership map.
2. **Spawn by preset:** Delegate only independent streams. Shared files are lead-owned unless interface-first contracts are explicitly defined.
3. **Two strikes and pivot:** Any worker failing twice on the same blocker escalates to lead.
4. **Reviewer required:** For pair/squad/full, run a dedicated review pass for regressions, security basics, and missing tests.
5. **Integrate + validate:** Lead integrates, runs quality gates, and reports final outcomes.

### Dependency Graph Gate (required before workers)

Planner must output a task graph with this minimum schema for every task:
- `id`
- `goal`
- `owned_files`
- `blocked_by` (list of task ids)
- `lane` (`parallel` or `sequential`)

Lead must enforce:
- Only tasks with `blocked_by = []` may be delegated immediately.
- `sequential` lane tasks are delegated one at a time in dependency order.
- `parallel` lane tasks may run concurrently only when file ownership does not overlap.
- After each task completes, recompute unblocked tasks and continue until graph is done.

### Autonomy Rule

- Do not ask the user whether to use agents for normal engineering tasks.
- Decide automatically using this router and briefly state the selected preset with rationale.
- Ask only when there is genuine ambiguity in intent or hard external constraints (budget, credentials, destructive operations).
<!-- END CODEX-SQUAD ROUTER -->
