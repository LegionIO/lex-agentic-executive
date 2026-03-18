# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module DissonanceResolution
          module Runners
            module CognitiveDissonanceResolution
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_dissonance_conflict(belief_a:, belief_b:, domain: :general,
                                             tension: nil, **)
                t = tension || Helpers::Constants::DEFAULT_TENSION
                conflict = engine.create_conflict(belief_a: belief_a, belief_b: belief_b,
                                                  domain: domain, tension: t)
                { success: true }.merge(conflict.to_h)
              end

              def apply_resolution_strategy(conflict_id:, strategy:, effectiveness: 0.3, **)
                result = engine.apply_strategy(conflict_id: conflict_id, strategy: strategy,
                                               effectiveness: effectiveness)
                return { success: false, error: 'conflict not found' } unless result

                { success: true }.merge(result.to_h)
              end

              def escalate_dissonance(conflict_id:, amount: 0.15, **)
                result = engine.escalate_conflict(conflict_id: conflict_id, amount: amount)
                return { success: false, error: 'conflict not found' } unless result

                { success: true }.merge(result.to_h)
              end

              def abandon_dissonance(conflict_id:, **)
                result = engine.abandon_conflict(conflict_id: conflict_id)
                return { success: false, error: 'conflict not found' } unless result

                { success: true }.merge(result.to_h)
              end

              def ongoing_dissonance_report(**)
                conflicts = engine.ongoing_conflicts
                { success: true, count: conflicts.size, conflicts: conflicts.map(&:to_h) }
              end

              def most_tense_report(limit: 5, **)
                conflicts = engine.most_tense(limit: limit)
                { success: true, limit: limit, conflicts: conflicts.map(&:to_h) }
              end

              def strategy_effectiveness_report(**)
                { success: true, strategies: engine.strategy_report, best: engine.best_strategy }
              end

              def dissonance_report(**)
                engine.dissonance_report
              end

              def update_dissonance_resolution(**)
                decayed = engine.decay_all
                { success: true, decayed: decayed, stats: engine.to_h }
              end

              def dissonance_resolution_stats(**)
                engine.to_h
              end
            end
          end
        end
      end
    end
  end
end
