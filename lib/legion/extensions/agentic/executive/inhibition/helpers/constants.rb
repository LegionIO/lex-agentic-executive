# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inhibition
          module Helpers
            module Constants
              IMPULSE_TYPES = %i[reactive habitual emotional social competitive].freeze

              INHIBITION_STRATEGIES = %i[suppression delay redirect substitute defer].freeze

              IMPULSE_STRENGTHS = {
                overwhelming: 1.0,
                strong:       0.75,
                moderate:     0.5,
                mild:         0.25,
                negligible:   0.1
              }.freeze

              INHIBITION_ALPHA         = 0.12
              FATIGUE_PER_INHIBITION   = 0.05
              FATIGUE_RECOVERY_RATE    = 0.02
              MAX_INHIBITION_LOG       = 200
              WILLPOWER_THRESHOLD      = 0.3
              AUTOMATIC_SUPPRESS_THRESHOLD = 0.2
              DELAY_DISCOUNT_RATE = 0.1
              STROOP_CONFLICT_THRESHOLD = 0.6
            end
          end
        end
      end
    end
  end
end
