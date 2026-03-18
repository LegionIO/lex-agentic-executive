# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module ExecutiveFunction
          module Helpers
            class ExecutiveController
              EF_COMPONENTS    = %i[inhibition shifting updating].freeze
              COMMON_EF_WEIGHT = 0.4
              SWITCH_COST      = 0.15
              INHIBITION_COST  = 0.1
              UPDATE_COST      = 0.08
              FATIGUE_RATE     = 0.01
              CAPACITY_ALPHA   = 0.12
              MAX_TASK_HISTORY = 200
              MAX_INHIBITIONS = 100

              attr_reader :current_task_set, :task_history, :inhibition_log, :update_log

              def initialize
                @components = EF_COMPONENTS.to_h { |n| [n, EfComponent.new(name: n)] }
                @current_task_set = nil
                @task_history    = []
                @inhibition_log  = []
                @update_log      = []
              end

              def inhibit(target:, reason:)
                comp = @components[:inhibition]
                return { success: false, reason: :insufficient_capacity } unless can_inhibit?

                comp.use(cost: INHIBITION_COST)
                apply_common_ef_fatigue(:inhibition)
                entry = { target: target, reason: reason, suppressed_at: Time.now.utc,
                          remaining_capacity: comp.effective_capacity }
                @inhibition_log << entry
                @inhibition_log = @inhibition_log.last(MAX_INHIBITIONS)
                { success: true, target: target, remaining_capacity: comp.effective_capacity }
              end

              def shift_task(from:, to:)
                comp = @components[:shifting]
                return { success: false, reason: :insufficient_capacity } unless can_shift?

                cost = same_task?(from, to) ? 0.0 : SWITCH_COST
                comp.use(cost: cost)
                apply_common_ef_fatigue(:shifting)

                old_task = @current_task_set
                @current_task_set = to
                @task_history << { from: from, to: to, switched_at: Time.now.utc, switch_cost: cost }
                @task_history = @task_history.last(MAX_TASK_HISTORY)

                { success: true, from: old_task, to: to, switch_cost: cost,
                  remaining_capacity: comp.effective_capacity }
              end

              def update_wm(slot:, old_value:, new_value:)
                comp = @components[:updating]
                return { success: false, reason: :insufficient_capacity } unless can_update?

                comp.use(cost: UPDATE_COST)
                apply_common_ef_fatigue(:updating)
                entry = { slot: slot, old_value: old_value, new_value: new_value,
                          updated_at: Time.now.utc, remaining_capacity: comp.effective_capacity }
                @update_log << entry
                { success: true, slot: slot, old_value: old_value, new_value: new_value,
                  remaining_capacity: comp.effective_capacity }
              end

              def common_ef_level
                values = @components.values.map(&:effective_capacity)
                avg    = values.sum / values.size.to_f
                (avg * (1.0 - COMMON_EF_WEIGHT)) + (avg * COMMON_EF_WEIGHT)
              end

              def can_inhibit?
                !@components[:inhibition].fatigued?
              end

              def can_shift?
                !@components[:shifting].fatigued?
              end

              def can_update?
                !@components[:updating].fatigued?
              end

              def tick
                @components.each_value(&:recover)
              end

              def component(name)
                @components[name.to_sym]
              end

              def to_h
                {
                  common_ef_level:   common_ef_level.round(4),
                  current_task_set:  @current_task_set,
                  components:        @components.transform_values(&:to_h),
                  task_history_size: @task_history.size,
                  inhibition_count:  @inhibition_log.size,
                  update_count:      @update_log.size
                }
              end

              private

              def same_task?(from, to)
                from.to_s == to.to_s
              end

              def apply_common_ef_fatigue(primary)
                EF_COMPONENTS.each do |name|
                  next if name == primary

                  @components[name].use(cost: FATIGUE_RATE)
                end
              end
            end
          end
        end
      end
    end
  end
end
