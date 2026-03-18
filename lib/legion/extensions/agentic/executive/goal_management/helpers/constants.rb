# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            module Constants
              MAX_GOALS          = 500
              MAX_DEPTH          = 10
              DEFAULT_PRIORITY   = 0.5
              PRIORITY_BOOST     = 0.1
              PRIORITY_DECAY     = 0.02
              PROGRESS_THRESHOLD = 0.9
              CONFLICT_THRESHOLD = 0.6

              GOAL_STATUSES = %i[proposed active blocked completed abandoned].freeze

              PRIORITY_LABELS = [
                { range: (0.8..1.0), label: :critical },
                { range: (0.6...0.8), label: :high },
                { range: (0.4...0.6), label: :moderate },
                { range: (0.2...0.4), label: :low },
                { range: (0.0...0.2), label: :trivial }
              ].freeze

              PROGRESS_LABELS = [
                { range: (0.9..1.0), label: :complete },
                { range: (0.7...0.9), label: :nearly_done },
                { range: (0.4...0.7), label: :in_progress },
                { range: (0.1...0.4), label: :started },
                { range: (0.0...0.1), label: :not_started }
              ].freeze

              CONFLICT_LABELS = [
                { range: (0.8..1.0), label: :severe },
                { range: (0.6...0.8), label: :significant },
                { range: (0.4...0.6), label: :moderate },
                { range: (0.2...0.4), label: :minor },
                { range: (0.0...0.2), label: :none }
              ].freeze
            end
          end
        end
      end
    end
  end
end
