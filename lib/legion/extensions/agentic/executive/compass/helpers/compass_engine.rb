# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Compass
          module Helpers
            class CompassEngine
              def initialize
                @bearings = {}
                @biases   = {}
              end

              def take_bearing(direction:, context:, confidence: nil)
                bearing = Bearing.new(direction: direction, context: context,
                                      confidence: confidence)
                @bearings[bearing.id] = bearing
                bearing
              end

              def register_bias(bias_type:, domain:, declination: nil, strength: nil)
                raise ArgumentError, 'too many biases' if @biases.size >= Constants::MAX_BIASES

                bias = MagneticBias.new(bias_type: bias_type, domain: domain,
                                        declination: declination, strength: strength)
                @biases[bias.id] = bias
                bias
              end

              def calibrate(bias_id:, amount: Constants::CALIBRATION_BOOST)
                fetch_bias(bias_id).correct!(amount: amount)
              end

              def true_north_offset
                return 0.0 if @biases.empty?

                total = @biases.values.sum(&:declination)
                (total / @biases.size).round(10)
              end

              def accuracy
                offset = true_north_offset
                (1.0 - offset).clamp(0.0, 1.0).round(10)
              end

              def accuracy_label
                Constants.label_for(Constants::ACCURACY_LABELS, accuracy)
              end

              def decay_biases!(rate: Constants::DECLINATION_DECAY)
                @biases.each_value { |b| b.decay!(rate: rate) }
                pruned = @biases.select { |_, b| b.negligible? && b.strength < 0.1 }.keys
                pruned.each { |id| @biases.delete(id) }
                { remaining: @biases.size, pruned: pruned.size }
              end

              def dominant_direction
                return nil if @bearings.empty?

                counts = Hash.new(0)
                @bearings.each_value { |b| counts[b.direction] += b.confidence }
                counts.max_by { |_, v| v }&.first
              end

              def bearings_by_direction
                result = Hash.new(0)
                @bearings.each_value { |b| result[b.direction] += 1 }
                result
              end

              def strongest_biases(limit: 5)
                @biases.values.sort_by { |b| -b.strength }.first(limit)
              end

              def compass_report
                {
                  total_bearings:     @bearings.size,
                  total_biases:       @biases.size,
                  accuracy:           accuracy,
                  accuracy_label:     accuracy_label,
                  true_north_offset:  true_north_offset,
                  dominant_direction: dominant_direction,
                  by_direction:       bearings_by_direction,
                  severe_biases:      @biases.count { |_, b| b.severe? }
                }
              end

              def all_bearings
                @bearings.values
              end

              def all_biases
                @biases.values
              end

              private

              def fetch_bias(id)
                @biases.fetch(id) { raise ArgumentError, "bias not found: #{id}" }
              end
            end
          end
        end
      end
    end
  end
end
