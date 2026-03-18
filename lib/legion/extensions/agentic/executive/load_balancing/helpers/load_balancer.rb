# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module LoadBalancing
          module Helpers
            class LoadBalancer
              include Constants

              def initialize
                @subsystems = {}
              end

              def register_subsystem(name:, subsystem_type: :general, capacity: DEFAULT_CAPACITY)
                prune_if_needed
                subsystem = Subsystem.new(
                  name:           name,
                  subsystem_type: subsystem_type,
                  capacity:       capacity
                )
                @subsystems[subsystem.id] = subsystem
                subsystem
              end

              def assign_load(subsystem_id:, amount:)
                subsystem = @subsystems[subsystem_id]
                return nil unless subsystem

                subsystem.add_load!(amount: amount)
              end

              def shed_load(subsystem_id:, amount:)
                subsystem = @subsystems[subsystem_id]
                return nil unless subsystem

                subsystem.shed_load!(amount: amount)
              end

              def auto_assign(amount:, subsystem_type: nil)
                candidates = if subsystem_type
                               @subsystems.values.select { |s| s.subsystem_type == subsystem_type.to_sym }
                             else
                               @subsystems.values
                             end
                return nil if candidates.empty?

                best = candidates.min_by(&:utilization)
                best.add_load!(amount: amount)
                best
              end

              def rebalance
                overloaded = @subsystems.values.select(&:overloaded?)
                underloaded = @subsystems.values.select(&:underloaded?)
                transfers = 0

                overloaded.each do |over|
                  target = underloaded.min_by(&:utilization)
                  break unless target

                  transfer_amount = [REBALANCE_STEP, over.current_load * 0.2].min
                  shed = over.shed_load!(amount: transfer_amount)
                  target.add_load!(amount: shed)
                  transfers += 1
                end

                transfers
              end

              def overloaded_subsystems
                @subsystems.values.select(&:overloaded?)
              end

              def underloaded_subsystems
                @subsystems.values.select(&:underloaded?)
              end

              def subsystems_by_type(subsystem_type:)
                st = subsystem_type.to_sym
                @subsystems.values.select { |s| s.subsystem_type == st }
              end

              def most_loaded(limit: 5)
                @subsystems.values.sort_by { |s| -s.utilization }.first(limit)
              end

              def overall_utilization
                return 0.0 if @subsystems.empty?

                utils = @subsystems.values.map(&:utilization)
                (utils.sum / utils.size).round(10)
              end

              def overall_health
                return 1.0 if @subsystems.empty?

                healths = @subsystems.values.map(&:health)
                (healths.sum / healths.size).round(10)
              end

              def balance_report
                {
                  total_subsystems:    @subsystems.size,
                  overloaded_count:    overloaded_subsystems.size,
                  underloaded_count:   underloaded_subsystems.size,
                  overall_utilization: overall_utilization,
                  overall_health:      overall_health,
                  most_loaded:         most_loaded(limit: 3).map(&:to_h)
                }
              end

              def to_h
                {
                  total_subsystems:    @subsystems.size,
                  overall_utilization: overall_utilization,
                  overall_health:      overall_health,
                  overloaded_count:    overloaded_subsystems.size
                }
              end

              private

              def prune_if_needed
                return if @subsystems.size < MAX_SUBSYSTEMS

                least_used = @subsystems.values.min_by(&:tasks_processed)
                @subsystems.delete(least_used.id) if least_used
              end
            end
          end
        end
      end
    end
  end
end
