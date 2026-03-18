# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Triage
          module Helpers
            class TriageEngine
              include Constants

              attr_reader :capacity

              def initialize
                @demands  = {}
                @capacity = CAPACITY_DEFAULT
              end

              def add_demand(description:, domain: :general, severity: :moderate, urgency: :soon)
                prune_if_needed
                demand = Demand.new(
                  description: description, domain: domain, severity: severity, urgency: urgency
                )
                @demands[demand.id] = demand
                drain_capacity!(demand.triage_score * CAPACITY_DRAIN)
                demand.triage!
                demand
              end

              def process_demand(demand_id:)
                demand = @demands[demand_id]
                return nil unless demand&.active?

                demand.process!
                demand
              end

              def complete_demand(demand_id:)
                demand = @demands[demand_id]
                return nil unless demand

                demand.complete!
                restore_capacity!(CAPACITY_RESTORE)
                demand
              end

              def defer_demand(demand_id:)
                demand = @demands[demand_id]
                return nil unless demand&.active?

                demand.defer!
                restore_capacity!(CAPACITY_RESTORE * 0.5)
                demand
              end

              def drop_demand(demand_id:)
                demand = @demands[demand_id]
                return nil unless demand&.active?

                demand.drop!
                restore_capacity!(CAPACITY_RESTORE)
                demand
              end

              def next_demand
                active_demands.max_by(&:triage_score)
              end

              def active_demands = @demands.values.select(&:active?)
              def red_demands = @demands.values.select(&:red?)
              def completed_demands = @demands.values.select { |d| d.status == :completed }
              def dropped_demands = @demands.values.select { |d| d.status == :dropped }
              def deferred_demands = @demands.values.select { |d| d.status == :deferred }

              def demands_by_severity(severity:)
                @demands.values.select { |d| d.severity == severity.to_sym }
              end

              def demands_by_domain(domain:)
                @demands.values.select { |d| d.domain == domain.to_sym }
              end

              def overloaded?
                @capacity <= OVERLOAD_THRESHOLD
              end

              def queue_pressure
                return 0.0 if @demands.empty?

                (active_demands.size.to_f / MAX_QUEUE_SIZE).clamp(0.0, 1.0).round(10)
              end

              def capacity_label = Constants.label_for(CAPACITY_LABELS, @capacity)
              def queue_label = Constants.label_for(QUEUE_LABELS, queue_pressure)

              def restore_capacity!(amount = CAPACITY_RESTORE)
                @capacity = (@capacity + amount).clamp(0.0, 1.0).round(10)
                self
              end

              def triage_report
                {
                  total_demands:  @demands.size,
                  active_count:   active_demands.size,
                  red_count:      red_demands.size,
                  completed:      completed_demands.size,
                  dropped:        dropped_demands.size,
                  deferred:       deferred_demands.size,
                  capacity:       @capacity,
                  capacity_label: capacity_label,
                  overloaded:     overloaded?,
                  queue_pressure: queue_pressure,
                  queue_label:    queue_label,
                  next_demand:    next_demand&.to_h
                }
              end

              def to_h
                {
                  total_demands: @demands.size,
                  active:        active_demands.size,
                  capacity:      @capacity,
                  overloaded:    overloaded?
                }
              end

              private

              def drain_capacity!(amount)
                @capacity = (@capacity - amount).clamp(0.0, 1.0).round(10)
              end

              def prune_if_needed
                return if @demands.size < MAX_DEMANDS

                oldest_completed = completed_demands.min_by(&:created_at)
                if oldest_completed
                  @demands.delete(oldest_completed.id)
                else
                  lowest = @demands.values.min_by(&:triage_score)
                  @demands.delete(lowest.id) if lowest
                end
              end
            end
          end
        end
      end
    end
  end
end
