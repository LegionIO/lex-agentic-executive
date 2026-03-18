# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inertia
          module Helpers
            module Constants
              MAX_BELIEFS = 300
              MAX_CHALLENGES = 500

              DEFAULT_INERTIA = 0.5
              INERTIA_GROWTH_RATE = 0.03
              INERTIA_REDUCTION_RATE = 0.05
              CONVICTION_THRESHOLD = 0.8
              FLEXIBILITY_THRESHOLD = 0.3

              INERTIA_LABELS = {
                (0.8..)     => :entrenched,
                (0.6...0.8) => :resistant,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :flexible,
                (..0.2)     => :fluid
              }.freeze

              CONVICTION_LABELS = {
                (0.8..)     => :absolute,
                (0.6...0.8) => :strong,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :tentative,
                (..0.2)     => :uncertain
              }.freeze

              BELIEF_DOMAINS = %i[
                factual causal procedural evaluative
                social predictive normative
              ].freeze
            end
          end
        end
      end
    end
  end
end
