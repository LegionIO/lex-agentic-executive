# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Control
          module Helpers
            module Constants
              MAX_GOALS = 20
              MAX_POLICIES = 50
              MAX_HISTORY = 200

              DEFAULT_EFFORT = 0.5
              EFFORT_FLOOR = 0.1
              EFFORT_CEILING = 1.0
              EFFORT_DECAY = 0.02
              EFFORT_RECOVERY = 0.03

              AUTOMATIC_THRESHOLD = 0.3
              CONTROLLED_THRESHOLD = 0.6
              OVERRIDE_THRESHOLD = 0.8

              CONFLICT_BOOST = 0.2
              ERROR_BOOST = 0.15
              NOVELTY_BOOST = 0.1
              ADAPTATION_ALPHA = 0.1

              CONTROL_MODES = %i[automatic controlled override].freeze
              GOAL_STATES = %i[active suspended completed abandoned].freeze

              EFFORT_LABELS = {
                (0.8..)     => :maximal,
                (0.6...0.8) => :effortful,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :low,
                (..0.2)     => :automatic
              }.freeze
            end
          end
        end
      end
    end
  end
end
