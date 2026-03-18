# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module ExecutiveFunction
          module Helpers
            class EfComponent
              DEFAULT_CAPACITY = 0.7
              CAPACITY_FLOOR   = 0.1
              CAPACITY_CEILING = 1.0
              RECOVERY_RATE    = 0.02

              attr_reader :name, :capacity, :fatigue, :recent_uses

              def initialize(name:, capacity: DEFAULT_CAPACITY)
                @name        = name
                @capacity    = capacity.clamp(CAPACITY_FLOOR, CAPACITY_CEILING)
                @fatigue     = 0.0
                @recent_uses = []
              end

              def use(cost:)
                @fatigue = [@fatigue + cost, capacity].min
                @recent_uses << { used_at: Time.now.utc, cost: cost }
                @recent_uses = @recent_uses.last(50)
              end

              def recover
                @fatigue = [@fatigue - RECOVERY_RATE, 0.0].max
              end

              def effective_capacity
                [@capacity - @fatigue, CAPACITY_FLOOR].max
              end

              def fatigued?
                effective_capacity <= CAPACITY_FLOOR + 0.05
              end

              def to_h
                {
                  name:               @name,
                  capacity:           @capacity,
                  fatigue:            @fatigue.round(4),
                  effective_capacity: effective_capacity.round(4),
                  fatigued:           fatigued?,
                  recent_use_count:   @recent_uses.size
                }
              end
            end
          end
        end
      end
    end
  end
end
