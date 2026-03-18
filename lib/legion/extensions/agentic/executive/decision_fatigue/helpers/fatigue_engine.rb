# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module DecisionFatigue
          module Helpers
            class FatigueEngine
              attr_reader :willpower, :total_decisions, :session_start

              def initialize
                @decisions       = []
                @willpower       = Constants::DEFAULT_WILLPOWER
                @total_decisions = 0
                @session_start   = Time.now.utc
                @next_id         = 1
              end

              def make_decision(label:, decision_type: :routine, complexity: 0.5)
                complexity = complexity.clamp(0.0, 1.0)
                cost       = complexity * Constants::DEPLETION_RATE
                @willpower = [@willpower - cost, Constants::QUALITY_FLOOR].max

                record = DecisionRecord.new(
                  id:              @next_id,
                  label:           label,
                  decision_type:   decision_type,
                  complexity:      complexity,
                  quality_at_time: current_quality,
                  willpower_cost:  cost
                )

                @next_id         += 1
                @total_decisions += 1
                @decisions << record
                @decisions.shift while @decisions.size > Constants::MAX_DECISIONS

                record
              end

              def current_quality
                @willpower.clamp(Constants::QUALITY_FLOOR, 1.0)
              end

              def quality_label
                Constants.quality_label_for(current_quality)
              end

              def rest!(amount: Constants::RECOVERY_RATE)
                @willpower = [@willpower + amount, 1.0].min
              end

              def full_rest!
                @willpower = Constants::DEFAULT_WILLPOWER
              end

              def decisions_since_rest
                @decisions.size
              end

              def decision_rate
                elapsed = [(Time.now.utc - @session_start) / 60.0, 1.0].max
                @total_decisions / elapsed
              end

              def should_rest?
                @willpower < 0.3
              end

              def recent_decisions(limit: 10)
                @decisions.last(limit)
              end

              def decisions_by_type(decision_type:)
                @decisions.select { |d| d.decision_type == decision_type }
              end

              def quality_trend(window: 10)
                recent = @decisions.last(window)
                return current_quality if recent.empty?

                recent.sum(&:quality_at_time) / recent.size
              end

              def fatigue_report
                {
                  willpower:         @willpower.round(4),
                  current_quality:   current_quality.round(4),
                  quality_label:     quality_label,
                  total_decisions:   @total_decisions,
                  session_decisions: @decisions.size,
                  decision_rate:     decision_rate.round(4),
                  should_rest:       should_rest?,
                  quality_trend:     quality_trend.round(4),
                  session_start:     @session_start
                }
              end

              def to_h
                {
                  willpower:       @willpower,
                  total_decisions: @total_decisions,
                  session_start:   @session_start,
                  decisions:       @decisions.map(&:to_h)
                }
              end
            end
          end
        end
      end
    end
  end
end
