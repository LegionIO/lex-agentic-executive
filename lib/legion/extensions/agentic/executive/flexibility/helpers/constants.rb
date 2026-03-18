# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Flexibility
          module Helpers
            module Constants
              MAX_TASK_SETS         = 30
              MAX_SWITCH_HISTORY    = 200
              MAX_RULES_PER_SET     = 20

              SWITCH_COST_BASE      = 0.15
              SWITCH_COST_DECAY     = 0.02
              PERSEVERATION_THRESHOLD = 0.7
              FLEXIBILITY_FLOOR     = 0.1
              DEFAULT_FLEXIBILITY   = 0.6
              ADAPTATION_ALPHA      = 0.1

              RULE_TYPES = %i[
                if_then mapping category sorting
                priority sequence conditional
              ].freeze

              FLEXIBILITY_LABELS = {
                (0.8..)     => :fluid,
                (0.6...0.8) => :flexible,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :rigid,
                (..0.2)     => :perseverative
              }.freeze
            end
          end
        end
      end
    end
  end
end
