# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module DecisionFatigue
          module Runners
            module DecisionFatigue
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def make_decision(label:, decision_type: :routine, complexity: 0.5, **)
                record = fatigue_engine.make_decision(
                  label:         label,
                  decision_type: decision_type,
                  complexity:    complexity
                )
                Legion::Logging.info "[decision_fatigue] decision made: label=#{label} type=#{decision_type} " \
                                     "complexity=#{complexity.round(2)} quality=#{record.quality_at_time.round(2)} " \
                                     "willpower=#{fatigue_engine.willpower.round(2)}"
                record.to_h
              end

              def fatigue_status(**)
                report = fatigue_engine.fatigue_report
                Legion::Logging.debug "[decision_fatigue] status: quality=#{report[:quality_label]} " \
                                      "willpower=#{report[:willpower]} total=#{report[:total_decisions]}"
                report
              end

              def rest(amount: nil, **)
                amt = amount || Helpers::Constants::RECOVERY_RATE
                before = fatigue_engine.willpower
                fatigue_engine.rest!(amount: amt)
                after = fatigue_engine.willpower
                Legion::Logging.debug "[decision_fatigue] rest: amount=#{amt} willpower #{before.round(2)}->#{after.round(2)}"
                {
                  recovered:     (after - before).round(4),
                  willpower:     after.round(4),
                  quality:       fatigue_engine.current_quality.round(4),
                  quality_label: fatigue_engine.quality_label
                }
              end

              def full_rest(**)
                before = fatigue_engine.willpower
                fatigue_engine.full_rest!
                Legion::Logging.info "[decision_fatigue] full_rest: willpower #{before.round(2)}->1.0"
                {
                  recovered:     (1.0 - before).round(4),
                  willpower:     1.0,
                  quality:       1.0,
                  quality_label: :optimal
                }
              end

              def recent_decisions(limit: 10, **)
                decisions = fatigue_engine.recent_decisions(limit: limit)
                Legion::Logging.debug "[decision_fatigue] recent_decisions: limit=#{limit} returned=#{decisions.size}"
                { decisions: decisions.map(&:to_h), count: decisions.size }
              end

              def decisions_by_type(decision_type:, **)
                decisions = fatigue_engine.decisions_by_type(decision_type: decision_type)
                Legion::Logging.debug "[decision_fatigue] decisions_by_type: type=#{decision_type} count=#{decisions.size}"
                { decisions: decisions.map(&:to_h), count: decisions.size, decision_type: decision_type }
              end

              def quality_trend(window: 10, **)
                trend = fatigue_engine.quality_trend(window: window)
                label = Helpers::Constants.quality_label_for(trend)
                Legion::Logging.debug "[decision_fatigue] quality_trend: window=#{window} trend=#{trend.round(2)} label=#{label}"
                { trend: trend.round(4), label: label, window: window }
              end

              def should_rest(**)
                result = fatigue_engine.should_rest?
                Legion::Logging.debug "[decision_fatigue] should_rest: #{result}"
                { should_rest: result, willpower: fatigue_engine.willpower.round(4) }
              end

              private

              def fatigue_engine
                @fatigue_engine ||= Helpers::FatigueEngine.new
              end
            end
          end
        end
      end
    end
  end
end
