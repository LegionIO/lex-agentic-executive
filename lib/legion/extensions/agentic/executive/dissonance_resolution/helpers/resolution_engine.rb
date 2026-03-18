# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module DissonanceResolution
          module Helpers
            class ResolutionEngine
              include Constants

              def initialize
                @conflicts         = {}
                @strategy_history  = Hash.new(0)
                @strategy_successes = Hash.new(0)
              end

              def create_conflict(belief_a:, belief_b:, domain: :general, tension: DEFAULT_TENSION)
                prune_if_needed
                conflict = DissonanceConflict.new(
                  belief_a: belief_a,
                  belief_b: belief_b,
                  domain:   domain,
                  tension:  tension
                )
                @conflicts[conflict.id] = conflict
                conflict
              end

              def apply_strategy(conflict_id:, strategy:, effectiveness: 0.3)
                conflict = @conflicts[conflict_id]
                return nil unless conflict

                strat = strategy.to_sym
                @strategy_history[strat] += 1
                conflict.apply_strategy!(strategy: strat, effectiveness: effectiveness)
                @strategy_successes[strat] += 1 if conflict.resolved?
                conflict
              end

              def escalate_conflict(conflict_id:, amount: 0.15)
                conflict = @conflicts[conflict_id]
                return nil unless conflict

                conflict.escalate!(amount: amount)
              end

              def abandon_conflict(conflict_id:)
                conflict = @conflicts[conflict_id]
                return nil unless conflict

                conflict.abandon!
              end

              def decay_all
                @conflicts.each_value(&:decay!)
                @conflicts.size
              end

              def best_strategy
                return nil if @strategy_history.empty?

                @strategy_history.max_by do |strat, uses|
                  rate = uses.positive? ? @strategy_successes[strat].to_f / uses : 0.0
                  rate
                end&.first
              end

              def strategy_report
                STRATEGIES.map do |strat|
                  uses = @strategy_history[strat]
                  successes = @strategy_successes[strat]
                  {
                    strategy:     strat,
                    uses:         uses,
                    successes:    successes,
                    success_rate: uses.positive? ? (successes.to_f / uses).round(4) : 0.0
                  }
                end
              end

              def ongoing_conflicts
                @conflicts.values.select { |c| c.outcome == :ongoing }
              end

              def resolved_conflicts
                @conflicts.values.select { |c| c.outcome == :resolved }
              end

              def conflicts_by_domain(domain:)
                d = domain.to_sym
                @conflicts.values.select { |c| c.domain == d }
              end

              def most_tense(limit: 5)
                @conflicts.values.sort_by { |c| -c.tension }.first(limit)
              end

              def resolution_rate
                total = @conflicts.size
                return 0.0 if total.zero?

                resolved = resolved_conflicts.size
                (resolved.to_f / total).round(4)
              end

              def average_tension
                return 0.0 if @conflicts.empty?

                tensions = @conflicts.values.map(&:tension)
                (tensions.sum / tensions.size).round(10)
              end

              def dissonance_report
                {
                  total_conflicts: @conflicts.size,
                  ongoing:         ongoing_conflicts.size,
                  resolved:        resolved_conflicts.size,
                  resolution_rate: resolution_rate,
                  average_tension: average_tension,
                  best_strategy:   best_strategy,
                  most_tense:      most_tense(limit: 3).map(&:to_h)
                }
              end

              def to_h
                {
                  total_conflicts: @conflicts.size,
                  ongoing:         ongoing_conflicts.size,
                  resolved:        resolved_conflicts.size,
                  resolution_rate: resolution_rate,
                  average_tension: average_tension
                }
              end

              private

              def prune_if_needed
                return if @conflicts.size < MAX_CONFLICTS

                oldest_resolved = resolved_conflicts.min_by(&:created_at)
                if oldest_resolved
                  @conflicts.delete(oldest_resolved.id)
                else
                  lowest = @conflicts.values.min_by(&:tension)
                  @conflicts.delete(lowest.id) if lowest
                end
              end
            end
          end
        end
      end
    end
  end
end
