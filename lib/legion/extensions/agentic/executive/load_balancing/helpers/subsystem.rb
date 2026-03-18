# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module LoadBalancing
          module Helpers
            class Subsystem
              include Constants

              attr_reader :id, :name, :subsystem_type, :capacity, :current_load,
                          :tasks_processed, :tasks_shed, :created_at

              def initialize(name:, subsystem_type: :general, capacity: DEFAULT_CAPACITY)
                @id              = SecureRandom.uuid
                @name            = name
                @subsystem_type  = subsystem_type.to_sym
                @capacity        = capacity.to_f.clamp(0.1, 5.0)
                @current_load    = 0.0
                @tasks_processed = 0
                @tasks_shed      = 0
                @created_at      = Time.now.utc
              end

              def utilization
                return 0.0 if @capacity.zero?

                (@current_load / @capacity).clamp(0.0, 1.5).round(10)
              end

              def load_label
                match = LOAD_LABELS.find { |range, _| range.cover?(utilization) }
                match ? match.last : :overloaded
              end

              def overloaded?
                utilization >= OVERLOAD_THRESHOLD
              end

              def underloaded?
                utilization <= UNDERLOAD_THRESHOLD
              end

              def health
                if overloaded?
                  [1.0 - ((utilization - OVERLOAD_THRESHOLD) * 3), 0.0].max.round(10)
                else
                  1.0
                end
              end

              def health_label
                match = HEALTH_LABELS.find { |range, _| range.cover?(health) }
                match ? match.last : :failing
              end

              def add_load!(amount:)
                @current_load = (@current_load + amount.to_f).clamp(0.0, @capacity * 1.5).round(10)
                @tasks_processed += 1
                self
              end

              def shed_load!(amount:)
                removed = [amount.to_f, @current_load].min
                @current_load = (@current_load - removed).clamp(0.0, @capacity * 1.5).round(10)
                @tasks_shed += 1
                removed
              end

              def available_capacity
                [(@capacity - @current_load), 0.0].max.round(10)
              end

              def to_h
                {
                  id:                 @id,
                  name:               @name,
                  subsystem_type:     @subsystem_type,
                  capacity:           @capacity,
                  current_load:       @current_load,
                  utilization:        utilization,
                  load_label:         load_label,
                  overloaded:         overloaded?,
                  health:             health,
                  health_label:       health_label,
                  available_capacity: available_capacity,
                  tasks_processed:    @tasks_processed,
                  tasks_shed:         @tasks_shed,
                  created_at:         @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
