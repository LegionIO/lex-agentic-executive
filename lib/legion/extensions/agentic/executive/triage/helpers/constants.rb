# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Triage
          module Helpers
            module Constants
              MAX_DEMANDS      = 500
              MAX_QUEUE_SIZE   = 100
              CAPACITY_DEFAULT = 1.0
              CAPACITY_DRAIN   = 0.05
              CAPACITY_RESTORE = 0.03
              OVERLOAD_THRESHOLD = 0.2

              SEVERITY_LEVELS = %i[critical major moderate minor trivial].freeze
              URGENCY_LEVELS  = %i[immediate urgent soon deferred indefinite].freeze

              SEVERITY_WEIGHTS = {
                critical: 1.0,
                major:    0.8,
                moderate: 0.5,
                minor:    0.3,
                trivial:  0.1
              }.freeze

              URGENCY_WEIGHTS = {
                immediate:  1.0,
                urgent:     0.8,
                soon:       0.5,
                deferred:   0.3,
                indefinite: 0.1
              }.freeze

              TRIAGE_LABELS = {
                (0.8..)     => :red,
                (0.6...0.8) => :orange,
                (0.4...0.6) => :yellow,
                (0.2...0.4) => :green,
                (..0.2)     => :white
              }.freeze

              CAPACITY_LABELS = {
                (0.8..)     => :fresh,
                (0.6...0.8) => :engaged,
                (0.4...0.6) => :strained,
                (0.2...0.4) => :depleted,
                (..0.2)     => :overloaded
              }.freeze

              QUEUE_LABELS = {
                (0.8..)     => :overwhelmed,
                (0.6...0.8) => :heavy,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :light,
                (..0.2)     => :empty
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
