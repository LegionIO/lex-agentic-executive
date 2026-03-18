# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module FlexibilityTraining
          module Helpers
            module Constants
              MAX_TASKS    = 100
              MAX_TRIALS   = 1000
              MAX_SESSIONS = 50

              DEFAULT_SWITCH_COST = 0.3
              IMPROVEMENT_RATE    = 0.02
              FATIGUE_RATE        = 0.01

              DIFFICULTY_LEVELS = %i[trivial easy moderate hard extreme].freeze
              TASK_DOMAINS      = %i[linguistic spatial numerical logical emotional social creative].freeze

              SWITCH_COST_LABELS = {
                (0.8..)     => :severe,
                (0.6...0.8) => :high,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :low,
                (..0.2)     => :minimal
              }.freeze

              FLEXIBILITY_LABELS = {
                (0.8..)     => :highly_flexible,
                (0.6...0.8) => :flexible,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :rigid,
                (..0.2)     => :inflexible
              }.freeze

              PROGRESS_LABELS = {
                (0.8..)     => :mastered,
                (0.6...0.8) => :proficient,
                (0.4...0.6) => :developing,
                (0.2...0.4) => :novice,
                (..0.2)     => :beginner
              }.freeze

              module_function

              def label_for(value, label_map)
                label_map.each { |range, label| return label if range.cover?(value) }
                nil
              end
            end
          end
        end
      end
    end
  end
end
