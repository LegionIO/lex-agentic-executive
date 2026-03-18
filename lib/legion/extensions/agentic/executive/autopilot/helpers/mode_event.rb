# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Autopilot
          module Helpers
            class ModeEvent
              include Constants

              attr_reader :id, :from_mode, :to_mode, :trigger, :energy_cost, :created_at

              def initialize(from_mode:, to_mode:, trigger:, energy_cost: 0.0)
                @id          = SecureRandom.uuid
                @from_mode   = from_mode.to_sym
                @to_mode     = to_mode.to_sym
                @trigger     = trigger.to_s
                @energy_cost = energy_cost.to_f.clamp(0.0, 1.0).round(10)
                @created_at  = Time.now.utc
              end

              def override?
                @from_mode == :autopilot && @to_mode == :deliberate
              end

              def engage_autopilot?
                @from_mode == :deliberate && @to_mode == :autopilot
              end

              def to_h
                {
                  id:               @id,
                  from_mode:        @from_mode,
                  to_mode:          @to_mode,
                  trigger:          @trigger,
                  energy_cost:      @energy_cost,
                  override:         override?,
                  engage_autopilot: engage_autopilot?,
                  created_at:       @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
