# Changelog

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
