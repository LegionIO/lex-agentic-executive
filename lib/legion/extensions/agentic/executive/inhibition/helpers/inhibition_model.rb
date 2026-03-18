# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inhibition
          module Helpers
            class InhibitionModel
              attr_reader :willpower, :inhibition_log, :suppressed_count, :failed_count, :redirected_count

              def initialize
                @willpower        = 0.8
                @inhibition_log   = []
                @suppressed_count = 0
                @failed_count     = 0
                @redirected_count = 0
              end

              def evaluate_impulse(impulse)
                if impulse.auto_suppressible?
                  :auto_suppress
                elsif @willpower < Constants::WILLPOWER_THRESHOLD
                  :failed
                else
                  select_strategy(impulse)
                end
              end

              def apply_strategy(impulse, strategy)
                deplete_willpower(impulse.strength) unless strategy == :auto_suppress

                case strategy
                when :failed
                  @failed_count += 1
                when :redirect
                  @redirected_count += 1
                  @suppressed_count += 1
                else
                  @suppressed_count += 1
                end

                entry = {
                  impulse_id: impulse.id,
                  type:       impulse.type,
                  action:     impulse.action,
                  strength:   impulse.strength,
                  strategy:   strategy,
                  willpower:  @willpower.round(4),
                  at:         Time.now.utc
                }

                @inhibition_log << entry
                @inhibition_log.shift while @inhibition_log.size > Constants::MAX_INHIBITION_LOG

                entry
              end

              def recover_willpower
                @willpower = [@willpower + Constants::FATIGUE_RECOVERY_RATE, 1.0].min
              end

              def willpower_status
                if @willpower >= 0.6
                  :healthy
                elsif @willpower >= Constants::WILLPOWER_THRESHOLD
                  :depleted
                else
                  :exhausted
                end
              end

              def success_rate
                total = @suppressed_count + @failed_count
                return 1.0 if total.zero?

                @suppressed_count.to_f / total
              end

              def delay_discount(reward_value, delay_ticks)
                reward_value / (1.0 + (Constants::DELAY_DISCOUNT_RATE * delay_ticks))
              end

              def stroop_conflict?(automatic_response, controlled_response)
                automatic_response != controlled_response &&
                  automatic_strength(automatic_response) >= Constants::STROOP_CONFLICT_THRESHOLD
              end

              private

              def select_strategy(impulse)
                case impulse.type
                when :habitual
                  :redirect
                when :emotional
                  impulse.overwhelming? ? :delay : :suppression
                when :social
                  :substitute
                when :competitive
                  :defer
                else
                  :suppression
                end
              end

              def deplete_willpower(strength)
                depletion  = Constants::FATIGUE_PER_INHIBITION * strength
                @willpower = [@willpower - depletion, 0.0].max
              end

              def automatic_strength(response)
                return response[:strength] if response.is_a?(Hash) && response.key?(:strength)

                Constants::STROOP_CONFLICT_THRESHOLD
              end
            end
          end
        end
      end
    end
  end
end
