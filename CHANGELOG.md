# Changelog

## [0.2.0] - 2026-04-21
### Added
- **Autonomous Goal-Setting Pipeline (G1-G5)** — GAIA can now convert intentions into goals, decompose them, dispatch execution, and receive feedback with no human intervention
- `Volition::Helpers::GoalBridge` — converts volition intentions into proposed goals via GoalManagement (G1)
- `GoalManagement::Helpers::Decomposer` — autonomous goal decomposition with domain-aware heuristic templates and optional LLM strategy (G2)
- `GoalManagement::Helpers::TaskDispatcher` — dispatches leaf goals to runners via `Legion::Runner.run` or Client instantiation, with per-domain argument builders and load-order guards (G3)
- `GoalEngine#reprioritize!` — event-driven priority adjustment with urgency-calibrated boost levels (G4)
- `GoalManagement::Helpers::FeedbackListener` — subscribes to `Legion::Events` for `task.completed`/`task.failed` and updates goal progress/status (G5)
- `GoalEngine#update_from_task_event` — thread-safe (Mutex) goal status update from task completion events
- `Goal#assign_task!` — associates a dispatched task_id and runner_mapping with a goal
- Auto-activation of proposed leaf goals before dispatch
- Auto-start of FeedbackListener on GoalManagement::Client initialization

## [0.1.12] - 2026-04-15
### Changed
- Set `mcp_tools?`, `mcp_tools_deferred?`, and `transport_required?` to `false` — internal cognitive pipeline extension

## [Unreleased]

### Fixed
- add success: true/false to all ProspectiveMemory runner methods to match LEX convention
- fix dominant_drive to use weighted scoring instead of raw strengths
- fix compute_urgency_drive to read arousal from gut_instinct first

## [0.1.9] - 2026-04-03

### Fixed
- Use `::Process::CLOCK_MONOTONIC` instead of `Process::CLOCK_MONOTONIC` in DualProcessEngine to avoid resolving to `Legion::Process`

## [0.1.8] - 2026-04-03

### Changed
- Fix drive synthesizer default values to avoid fabricating urgency, epistemic, and social drive without evidence
- Return 0.0 (not 0.5) for arousal and trust when no signal is present
- Short-circuit epistemic and social drive to 0.0 when prediction and mesh/trust state are empty
- Lower calm gut signal from 0.1 to 0.05 and unknown signals from 0.3 to 0.0

## [0.1.7] - 2026-03-31

### Added
- Proactive outreach evaluation in Volition `form_intentions`
- 4 trigger types: insight, check_in, milestone, curiosity
- Attachment style gating (avoidant suppresses proactive)
- Priority-based trigger selection

## [0.1.6] - 2026-03-26

### Changed
- fix remote_invocable? to use class method for local dispatch

## [0.1.5] - 2026-03-22

### Changed
- Add 7 legion sub-gem runtime dependencies to gemspec (legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport)
- Update spec_helper to require real sub-gem helpers and wire Helpers::Lex with all helper modules

## [0.1.3] - 2026-03-21

### Changed
- Working memory CAPACITY reduced from 7 to 4 (Cowan 2001)
- Chunking WORKING_MEMORY_CAPACITY updated from 7 to 4
- Effective max remains 7 via CHUNK_BONUS (4 base + 3 bonus)

## [0.1.1] - 2026-03-18

### Changed
- Enforce IMPULSE_TYPES validation in InhibitionStore#create_impulse (returns nil for invalid type)
- Enforce STRATEGIES validation in ResolutionEngine#apply_strategy (returns nil for invalid strategy)
- Enforce DISENGAGE_REASONS validation in DisengagementEngine#disengage_goal (raises ArgumentError)
- Enforce DECISION_OUTCOMES validation in DualProcessEngine#record_outcome (returns failure hash)

## [0.1.0] - 2026-03-18

### Added
- Initial release as domain consolidation gem
- Consolidated source extensions into unified domain gem under `Legion::Extensions::Agentic::<Domain>`
- All sub-modules loaded from single entry point
- Full spec suite with zero failures
- RuboCop compliance across all files
