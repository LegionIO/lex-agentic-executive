# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module DecisionFatigue
          module Helpers
            module Constants
              MAX_DECISIONS = 500
              DEFAULT_WILLPOWER = 1.0
              DEPLETION_RATE   = 0.05
              RECOVERY_RATE    = 0.08
              QUALITY_FLOOR    = 0.2

              QUALITY_LABELS = [
                { range: (0.85..1.0),  label: :optimal     },
                { range: (0.65..0.85), label: :good        },
                { range: (0.45..0.65), label: :adequate    },
                { range: (0.25..0.45), label: :compromised },
                { range: (0.0..0.25),  label: :depleted    }
              ].freeze

              DECISION_TYPES = %i[analytical evaluative creative routine social moral].freeze

              COMPLEXITY_LABELS = [
                { range: (0.0..0.2),  label: :trivial      },
                { range: (0.2..0.4),  label: :simple       },
                { range: (0.4..0.6),  label: :moderate     },
                { range: (0.6..0.8),  label: :complex      },
                { range: (0.8..1.0),  label: :overwhelming }
              ].freeze

              module_function

              def quality_label_for(value)
                entry = QUALITY_LABELS.find { |e| e[:range].cover?(value) }
                entry ? entry[:label] : :depleted
              end

              def complexity_label_for(value)
                entry = COMPLEXITY_LABELS.find { |e| e[:range].cover?(value) }
                entry ? entry[:label] : :overwhelming
              end
            end
          end
        end
      end
    end
  end
end
