# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module FlexibilityTraining
          module Helpers
            class SwitchTrial
              attr_reader :id, :from_task_id, :to_task_id, :switch_cost, :accuracy, :created_at

              def initialize(from_task_id:, to_task_id:, switch_cost:, accuracy:)
                @id           = SecureRandom.uuid
                @from_task_id = from_task_id
                @to_task_id   = to_task_id
                @switch_cost  = switch_cost.clamp(0.0, 1.0).round(10)
                @accuracy     = accuracy.clamp(0.0, 1.0).round(10)
                @created_at   = Time.now.utc
              end

              def costly?
                @switch_cost > 0.5
              end

              def successful?
                @accuracy > 0.7
              end

              def switch_cost_label
                Constants.label_for(@switch_cost, Constants::SWITCH_COST_LABELS)
              end

              def to_h
                {
                  id:                @id,
                  from_task_id:      @from_task_id,
                  to_task_id:        @to_task_id,
                  switch_cost:       @switch_cost,
                  accuracy:          @accuracy,
                  costly:            costly?,
                  successful:        successful?,
                  switch_cost_label: switch_cost_label,
                  created_at:        @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
