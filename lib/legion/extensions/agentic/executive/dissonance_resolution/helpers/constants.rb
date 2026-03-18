# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module DissonanceResolution
          module Helpers
            module Constants
              MAX_CONFLICTS = 200
              MAX_STRATEGIES = 50

              DEFAULT_TENSION = 0.5
              TENSION_DECAY = 0.03
              RESOLUTION_THRESHOLD = 0.2

              STRATEGIES = %i[
                belief_change behavior_change add_consonant
                trivialize reframe seek_information
                compartmentalize rationalize avoid
              ].freeze

              TENSION_LABELS = {
                (0.8..)     => :agonizing,
                (0.6...0.8) => :distressing,
                (0.4...0.6) => :uncomfortable,
                (0.2...0.4) => :mild,
                (..0.2)     => :resolved
              }.freeze

              OUTCOME_LABELS = %i[resolved partially_resolved ongoing escalated abandoned].freeze
            end
          end
        end
      end
    end
  end
end
