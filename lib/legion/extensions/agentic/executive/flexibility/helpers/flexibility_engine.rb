# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Flexibility
          module Helpers
            class FlexibilityEngine
              include Constants

              attr_reader :task_sets, :current_set_id, :switch_history, :switch_cost, :flexibility

              def initialize
                @task_sets      = {}
                @current_set_id = nil
                @switch_cost    = 0.0
                @flexibility    = DEFAULT_FLEXIBILITY
                @switch_history = []
                @counter        = 0
              end

              def create_task_set(name:, domain: :general)
                return nil if @task_sets.size >= MAX_TASK_SETS

                @counter += 1
                set_id = :"set_#{@counter}"
                ts = TaskSet.new(id: set_id, name: name, domain: domain)
                @task_sets[set_id] = ts
                @current_set_id ||= set_id
                ts
              end

              def add_rule(set_id:, type:, condition:, action:)
                ts = @task_sets[set_id]
                return nil unless ts

                ts.add_rule(type: type, condition: condition, action: action)
              end

              def switch_to(set_id:)
                return nil unless @task_sets.key?(set_id)
                return @task_sets[set_id] if set_id == @current_set_id

                old_id = @current_set_id
                @task_sets[old_id]&.deactivate
                @task_sets[set_id].activate
                @current_set_id = set_id
                @switch_cost = SWITCH_COST_BASE
                update_flexibility(:success)
                record_switch(from: old_id, to: set_id)
                @task_sets[set_id]
              end

              def current_set
                @current_set_id ? @task_sets[@current_set_id] : nil
              end

              def flexibility_label
                FLEXIBILITY_LABELS.each { |range, lbl| return lbl if range.cover?(@flexibility) }
                :perseverative
              end

              def perseverating?
                cs = current_set
                return false unless cs

                cs.dominant? && @flexibility < 0.4
              end

              def available_sets
                @task_sets.values.reject { |ts| ts.id == @current_set_id }.map(&:to_h)
              end

              def tick
                @switch_cost = [@switch_cost - SWITCH_COST_DECAY, 0.0].max
              end

              def to_h
                {
                  current_set:   @current_set_id,
                  set_count:     @task_sets.size,
                  switch_cost:   @switch_cost.round(4),
                  flexibility:   @flexibility.round(4),
                  label:         flexibility_label,
                  perseverating: perseverating?,
                  switch_count:  @switch_history.size
                }
              end

              private

              def update_flexibility(outcome)
                target = outcome == :success ? 1.0 : 0.0
                @flexibility += ADAPTATION_ALPHA * (target - @flexibility)
                @flexibility = @flexibility.clamp(FLEXIBILITY_FLOOR, 1.0)
              end

              def record_switch(from:, to:)
                @switch_history << { from: from, to: to, cost: @switch_cost, at: Time.now.utc }
                @switch_history.shift while @switch_history.size > MAX_SWITCH_HISTORY
              end
            end
          end
        end
      end
    end
  end
end
