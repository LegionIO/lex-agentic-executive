# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inhibition
          module Runners
            module Inhibition
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def update_inhibition(tick_results: {}, **)
                detect_impulse_triggers(tick_results)
                inhibition_store.recover

                summary = inhibition_store.stats
                Legion::Logging.debug "[inhibition] willpower=#{summary[:willpower]} " \
                                      "status=#{summary[:willpower_status]} " \
                                      "success_rate=#{summary[:success_rate]}"

                summary
              end

              def evaluate_impulse(action:, type: :reactive, strength: :moderate, source: nil, context: {}, **)
                type = type.to_sym
                unless Helpers::Constants::IMPULSE_TYPES.include?(type)
                  Legion::Logging.warn "[inhibition] unknown impulse type: #{type}"
                  return { success: false, error: "unknown impulse type: #{type}" }
                end

                impulse = inhibition_store.create_impulse(
                  type:     type,
                  action:   action,
                  strength: strength,
                  source:   source,
                  context:  context
                )

                result = inhibition_store.evaluate_and_apply(impulse)

                Legion::Logging.info "[inhibition] impulse evaluated: action=#{action} " \
                                     "type=#{type} strategy=#{result[:strategy]}"

                {
                  success:    true,
                  impulse_id: impulse.id,
                  action:     action,
                  type:       type,
                  strength:   impulse.strength,
                  strategy:   result[:strategy],
                  allowed:    result[:strategy] == :failed,
                  log_entry:  result[:log_entry]
                }
              end

              def delay_gratification(reward:, delay:, **)
                present_value = inhibition_store.model.delay_discount(reward.to_f, delay.to_i)
                worth_waiting = present_value >= (reward.to_f * 0.7)

                Legion::Logging.debug "[inhibition] delay_gratification: reward=#{reward} delay=#{delay} " \
                                      "present_value=#{present_value.round(4)} worth_waiting=#{worth_waiting}"

                {
                  reward:        reward,
                  delay:         delay,
                  present_value: present_value.round(4),
                  discount_rate: Helpers::Constants::DELAY_DISCOUNT_RATE,
                  worth_waiting: worth_waiting
                }
              end

              def check_stroop(automatic:, controlled:, **)
                conflict = inhibition_store.model.stroop_conflict?(automatic, controlled)

                Legion::Logging.debug "[inhibition] stroop check: conflict=#{conflict}"

                {
                  automatic:  automatic,
                  controlled: controlled,
                  conflict:   conflict,
                  threshold:  Helpers::Constants::STROOP_CONFLICT_THRESHOLD
                }
              end

              def willpower_status(**)
                model = inhibition_store.model
                Legion::Logging.debug "[inhibition] willpower=#{model.willpower.round(4)} status=#{model.willpower_status}"

                {
                  willpower:    model.willpower.round(4),
                  status:       model.willpower_status,
                  threshold:    Helpers::Constants::WILLPOWER_THRESHOLD,
                  success_rate: model.success_rate.round(4)
                }
              end

              def inhibition_history(**)
                log = inhibition_store.recent_log
                Legion::Logging.debug "[inhibition] history: #{log.size} entries"
                { log: log, total: inhibition_store.model.inhibition_log.size }
              end

              def inhibition_stats(**)
                Legion::Logging.debug '[inhibition] stats requested'
                inhibition_store.stats
              end

              private

              def inhibition_store
                @inhibition_store ||= Helpers::InhibitionStore.new
              end

              def detect_impulse_triggers(tick_results)
                detect_emotional_impulse(tick_results)
                detect_competitive_impulse(tick_results)
                detect_reactive_impulse(tick_results)
              end

              def detect_emotional_impulse(tick_results)
                arousal = tick_results.dig(:emotional_evaluation, :arousal)
                return unless arousal && arousal > 0.8

                strength = arousal > 0.95 ? :strong : :moderate
                inhibition_store.create_impulse(type: :emotional, action: :emotional_reaction, strength: strength)
                result = inhibition_store.evaluate_and_apply(inhibition_store.impulses.last)
                Legion::Logging.debug "[inhibition] auto-detected emotional impulse: strategy=#{result[:strategy]}"
              end

              def detect_competitive_impulse(tick_results)
                conflict_severity = tick_results.dig(:conflict, :severity)
                return unless conflict_severity && conflict_severity >= 3

                strength = conflict_severity >= 4 ? :strong : :moderate
                inhibition_store.create_impulse(type: :competitive, action: :conflict_escalation, strength: strength)
                result = inhibition_store.evaluate_and_apply(inhibition_store.impulses.last)
                Legion::Logging.debug "[inhibition] auto-detected competitive impulse: strategy=#{result[:strategy]}"
              end

              def detect_reactive_impulse(tick_results)
                error_rate = tick_results.dig(:prediction_engine, :error_rate)
                return unless error_rate && error_rate > 0.75

                inhibition_store.create_impulse(type: :reactive, action: :reactive_correction, strength: :mild)
                result = inhibition_store.evaluate_and_apply(inhibition_store.impulses.last)
                Legion::Logging.debug "[inhibition] auto-detected reactive impulse: strategy=#{result[:strategy]}"
              end
            end
          end
        end
      end
    end
  end
end
