# lex-agentic-executive

**Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## What Is This Gem?

Domain consolidation gem for executive function, goal management, planning, and cognitive control. Bundles 23 source extensions into one loadable unit under `Legion::Extensions::Agentic::Executive`.

**Gem**: `lex-agentic-executive`
**Version**: 0.1.0
**Namespace**: `Legion::Extensions::Agentic::Executive`

## Sub-Modules

| Sub-Module | Source Gem | Purpose |
|---|---|---|
| `Executive::Control` | `lex-cognitive-control` | Conflict monitoring, error detection, adaptive control signals |
| `Executive::ExecutiveFunction` | `lex-executive-function` | Miyake three-factor model: updating, flexibility, inhibition |
| `Executive::GoalManagement` | `lex-goal-management` | Hierarchical goal registry — decomposition, priority, lifecycle |
| `Executive::Inhibition` | `lex-inhibition` | Stop-signal model, prepotent response suppression |
| `Executive::Planning` | `lex-planning` | Goal-directed plan management — dependency graphs, replan limit |
| `Executive::Volition` | `lex-volition` | Five drives synthesized into intention stack — maps to `action_selection` tick phase |
| `Executive::WorkingMemory` | `lex-working-memory` | Baddeley & Hitch — capacity-limited buffer, verbal/spatial/episodic channels |
| `Executive::Flexibility` | `lex-cognitive-flexibility` | Cognitive flexibility — task switching, mental set shifting |
| `Executive::FlexibilityTraining` | `lex-cognitive-flexibility-training` | Structured training for cognitive flexibility improvement |
| `Executive::Load` | `lex-cognitive-load` | Sweller three-component model — intrinsic/extraneous/germane load |
| `Executive::LoadBalancing` | `lex-cognitive-load-balancing` | Load distribution across cognitive resources |
| `Executive::Disengagement` | `lex-cognitive-disengagement` | Controlled disengagement from tasks or mental sets |
| `Executive::Triage` | `lex-cognitive-triage` | Priority-based task selection under resource constraints |
| `Executive::Chunking` | `lex-cognitive-chunking` | Information compression into manageable units |
| `Executive::Inertia` | `lex-cognitive-inertia` | Resistance to switching — persistence in current cognitive mode |
| `Executive::Dwell` | `lex-cognitive-dwell` | Sustained focus on a single topic or problem |
| `Executive::Autopilot` | `lex-cognitive-autopilot` | Habitual/automatic processing mode |
| `Executive::DissonanceResolution` | `lex-cognitive-dissonance-resolution` | Resolution strategies for cognitive dissonance |
| `Executive::Compass` | `lex-cognitive-compass` | Goal-direction and navigation toward targets |
| `Executive::DecisionFatigue` | `lex-decision-fatigue` | Decision quality degradation after sustained choices |
| `Executive::DualProcess` | `lex-dual-process` | Kahneman System 1/System 2 routing |
| `Executive::ProspectiveMemory` | `lex-prospective-memory` | Memory for future intentions — reminder management |
| `Executive::CognitiveDebt` | `lex-cognitive-debt` | Accumulated cognitive obligations and deferred processing |

## Tick Integration

`Executive::Volition` maps to the `action_selection` tick phase via `form_intentions`.

## Development

```bash
bundle install
bundle exec rspec        # 2084 examples, 0 failures
bundle exec rubocop      # 0 offenses
```
