# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          module Helpers
            module Constants
              # Maximum active intentions
              MAX_INTENTIONS = 7

              # Drive sources and their default weights
              DRIVE_WEIGHTS = {
                curiosity:  0.25,  # from lex-curiosity wonder intensity
                corrective: 0.20,  # from lex-reflection adaptation recommendations
                urgency:    0.20,  # from lex-emotion gut signal + arousal
                epistemic:  0.20,  # from lex-prediction confidence gaps
                social:     0.15   # from lex-trust + mesh signals
              }.freeze

              # Minimum drive strength to generate an intention
              DRIVE_THRESHOLD = 0.15

              # Intention decay per tick when not reinforced
              INTENTION_DECAY = 0.05

              # Intention salience floor before removal
              INTENTION_FLOOR = 0.1

              # Maximum intention age in ticks before forced expiry
              MAX_INTENTION_AGE = 100

              # Drive labels for narrative output
              DRIVE_LABELS = {
                curiosity:  'knowledge seeking',
                corrective: 'self-improvement',
                urgency:    'urgent response',
                epistemic:  'uncertainty reduction',
                social:     'collaborative engagement'
              }.freeze

              # Intention states
              STATES = %i[active suspended completed expired].freeze
            end
          end
        end
      end
    end
  end
end
