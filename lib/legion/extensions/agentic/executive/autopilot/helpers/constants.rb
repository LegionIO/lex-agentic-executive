# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Autopilot
          module Helpers
            module Constants
              MAX_ROUTINES      = 200
              MAX_EVENTS        = 500
              FAMILIARITY_BOOST = 0.08
              FAMILIARITY_DECAY = 0.02
              AUTOPILOT_THRESHOLD = 0.7
              DELIBERATE_THRESHOLD = 0.3
              OVERRIDE_COST     = 0.15
              AUTOPILOT_COST    = 0.02
              DELIBERATE_COST   = 0.10
              DEFAULT_ENERGY    = 1.0

              PROCESSING_MODES = %i[autopilot deliberate transitioning].freeze

              TASK_DOMAINS = %i[
                routine analysis creative social emergency
                administrative technical unknown
              ].freeze

              FAMILIARITY_LABELS = {
                (0.8..)     => :expert,
                (0.6...0.8) => :proficient,
                (0.4...0.6) => :familiar,
                (0.2...0.4) => :learning,
                (..0.2)     => :novel
              }.freeze

              MODE_LABELS = {
                (0.8..)     => :deep_autopilot,
                (0.6...0.8) => :light_autopilot,
                (0.4...0.6) => :mixed,
                (0.2...0.4) => :mostly_deliberate,
                (..0.2)     => :full_deliberate
              }.freeze

              ENERGY_LABELS = {
                (0.8..)     => :energized,
                (0.6...0.8) => :steady,
                (0.4...0.6) => :tiring,
                (0.2...0.4) => :fatigued,
                (..0.2)     => :exhausted
              }.freeze

              def self.label_for(labels, value)
                match = labels.find { |range, _| range.cover?(value) }
                match&.last
              end
            end
          end
        end
      end
    end
  end
end
