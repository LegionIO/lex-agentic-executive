# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inertia
          module Helpers
            class InertiaEngine
              include Constants

              def initialize
                @beliefs = {}
              end

              def form_belief(content:, domain: :factual, conviction: 0.5)
                prune_if_needed
                belief = Belief.new(content: content, domain: domain, conviction: conviction)
                @beliefs[belief.id] = belief
                belief
              end

              def challenge_belief(belief_id:, strength: 0.5)
                belief = @beliefs[belief_id]
                return nil unless belief

                outcome = belief.challenge!(strength: strength)
                { outcome: outcome, belief: belief }
              end

              def reinforce_belief(belief_id:, amount: 0.1)
                belief = @beliefs[belief_id]
                return nil unless belief

                belief.reinforce!(amount: amount)
              end

              def entrenched_beliefs
                @beliefs.values.select(&:entrenched?)
              end

              def flexible_beliefs
                @beliefs.values.select(&:flexible?)
              end

              def beliefs_by_domain(domain:)
                d = domain.to_sym
                @beliefs.values.select { |b| b.domain == d }
              end

              def most_resistant(limit: 5)
                @beliefs.values.sort_by { |b| -b.resistance_rate }.first(limit)
              end

              def average_inertia
                return DEFAULT_INERTIA if @beliefs.empty?

                inertias = @beliefs.values.map(&:inertia)
                (inertias.sum / inertias.size).round(10)
              end

              def average_conviction
                return 0.5 if @beliefs.empty?

                convictions = @beliefs.values.map(&:conviction)
                (convictions.sum / convictions.size).round(10)
              end

              def overall_flexibility
                return 0.5 if @beliefs.empty?

                (1.0 - average_inertia).round(10)
              end

              def inertia_report
                {
                  total_beliefs:       @beliefs.size,
                  entrenched_count:    entrenched_beliefs.size,
                  flexible_count:      flexible_beliefs.size,
                  average_inertia:     average_inertia,
                  average_conviction:  average_conviction,
                  overall_flexibility: overall_flexibility,
                  most_resistant:      most_resistant(limit: 3).map(&:to_h)
                }
              end

              def to_h
                {
                  total_beliefs:       @beliefs.size,
                  entrenched_count:    entrenched_beliefs.size,
                  flexible_count:      flexible_beliefs.size,
                  average_inertia:     average_inertia,
                  overall_flexibility: overall_flexibility
                }
              end

              private

              def prune_if_needed
                return if @beliefs.size < MAX_BELIEFS

                most_flexible = @beliefs.values.min_by(&:inertia)
                @beliefs.delete(most_flexible.id) if most_flexible
              end
            end
          end
        end
      end
    end
  end
end
