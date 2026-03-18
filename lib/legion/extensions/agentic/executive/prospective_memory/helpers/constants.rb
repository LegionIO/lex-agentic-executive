# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module ProspectiveMemory
          module Helpers
            module Constants
              MAX_INTENTIONS   = 300
              DEFAULT_URGENCY  = 0.5
              URGENCY_DECAY    = 0.01
              URGENCY_BOOST    = 0.1
              CHECK_INTERVAL   = 60

              URGENCY_LABELS = {
                (0.8..)     => :critical,
                (0.6...0.8) => :high,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :low,
                (..0.2)     => :deferred
              }.freeze

              STATUS_TYPES  = %i[pending monitoring triggered executed expired cancelled].freeze
              TRIGGER_TYPES = %i[time_based event_based context_based activity_based].freeze
            end
          end
        end
      end
    end
  end
end
