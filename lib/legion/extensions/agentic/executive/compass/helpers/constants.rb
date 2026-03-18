# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Compass
          module Helpers
            module Constants
              # Cardinal directions mapped to value axes
              CARDINAL_DIRECTIONS = {
                north: :truth,
                east:  :utility,
                south: :beauty,
                west:  :safety
              }.freeze

              # Intercardinal directions (blended values)
              INTERCARDINAL_DIRECTIONS = {
                northeast: %i[truth utility],
                southeast: %i[utility beauty],
                southwest: %i[beauty safety],
                northwest: %i[safety truth]
              }.freeze

              # Bias types that cause magnetic declination
              BIAS_TYPES = %i[
                confirmation anchoring availability recency
                authority framing sunk_cost optimism
              ].freeze

              MAX_COMPASSES     = 50
              MAX_BIASES        = 20
              DECLINATION_DECAY = 0.02
              CALIBRATION_BOOST = 0.15

              # Bearing accuracy labels
              ACCURACY_LABELS = [
                [(0.8..),      :precise],
                [(0.6...0.8),  :reliable],
                [(0.4...0.6),  :approximate],
                [(0.2...0.4),  :drifting],
                [(..0.2),      :lost]
              ].freeze

              # Declination severity labels
              DECLINATION_LABELS = [
                [(0.8..),      :severe],
                [(0.6...0.8),  :significant],
                [(0.4...0.6),  :moderate],
                [(0.2...0.4),  :mild],
                [(..0.2),      :negligible]
              ].freeze

              def self.label_for(table, value)
                table.each { |range, label| return label if range.cover?(value) }
                table.last.last
              end
            end
          end
        end
      end
    end
  end
end
