# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inhibition
          module Helpers
            class InhibitionStore
              attr_reader :model, :impulses

              def initialize
                @model = InhibitionModel.new
                @impulses = []
              end

              def create_impulse(type:, action:, strength:, source: nil, context: {})
                return nil unless Constants::IMPULSE_TYPES.include?(type.to_sym)

                resolved_strength = resolve_strength(strength)

                impulse = Impulse.new(
                  type:     type,
                  action:   action,
                  strength: resolved_strength,
                  source:   source,
                  context:  context
                )

                @impulses << impulse
                impulse
              end

              def evaluate_and_apply(impulse)
                strategy = @model.evaluate_impulse(impulse)
                entry    = @model.apply_strategy(impulse, strategy)
                { strategy: strategy, log_entry: entry }
              end

              def recover
                @model.recover_willpower
              end

              def stats
                {
                  willpower:        @model.willpower.round(4),
                  willpower_status: @model.willpower_status,
                  suppressed:       @model.suppressed_count,
                  failed:           @model.failed_count,
                  redirected:       @model.redirected_count,
                  success_rate:     @model.success_rate.round(4),
                  log_size:         @model.inhibition_log.size,
                  total_impulses:   @impulses.size
                }
              end

              def recent_log(limit = 20)
                @model.inhibition_log.last(limit)
              end

              private

              def resolve_strength(strength)
                return strength if strength.is_a?(Float) || strength.is_a?(Integer)

                Constants::IMPULSE_STRENGTHS.fetch(strength.to_sym, Constants::IMPULSE_STRENGTHS[:moderate])
              end
            end
          end
        end
      end
    end
  end
end
