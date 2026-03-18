# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module LoadBalancing
          module Helpers
            module Constants
              MAX_SUBSYSTEMS = 50
              MAX_TASKS = 500

              DEFAULT_CAPACITY = 1.0
              OVERLOAD_THRESHOLD = 0.85
              UNDERLOAD_THRESHOLD = 0.2
              REBALANCE_STEP = 0.1

              LOAD_LABELS = {
                (0.85..)     => :overloaded,
                (0.7...0.85) => :heavy,
                (0.4...0.7)  => :balanced,
                (0.2...0.4)  => :light,
                (..0.2)      => :idle
              }.freeze

              HEALTH_LABELS = {
                (0.8..)     => :excellent,
                (0.6...0.8) => :good,
                (0.4...0.6) => :fair,
                (0.2...0.4) => :strained,
                (..0.2)     => :failing
              }.freeze

              SUBSYSTEM_TYPES = %i[
                perception reasoning memory attention
                language planning motor emotional
              ].freeze
            end
          end
        end
      end
    end
  end
end
