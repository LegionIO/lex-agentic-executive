# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Compass
          module Helpers
            class Bearing
              attr_reader :id, :direction, :value_axis, :context,
                          :taken_at
              attr_accessor :confidence

              def initialize(direction:, context:, confidence: nil)
                validate_direction!(direction)
                @id         = SecureRandom.uuid
                @direction  = direction.to_sym
                @value_axis = resolve_axis(direction.to_sym)
                @context    = context.to_s
                @confidence = (confidence || 0.7).to_f.clamp(0.0, 1.0).round(10)
                @taken_at   = Time.now.utc
              end

              def reliable?
                @confidence >= 0.6
              end

              def lost?
                @confidence < 0.2
              end

              def cardinal?
                Constants::CARDINAL_DIRECTIONS.key?(@direction)
              end

              def accuracy_label
                Constants.label_for(Constants::ACCURACY_LABELS, @confidence)
              end

              def to_h
                {
                  id:             @id,
                  direction:      @direction,
                  value_axis:     @value_axis,
                  context:        @context,
                  confidence:     @confidence,
                  accuracy_label: accuracy_label,
                  cardinal:       cardinal?,
                  reliable:       reliable?,
                  lost:           lost?,
                  taken_at:       @taken_at
                }
              end

              private

              def resolve_axis(dir)
                Constants::CARDINAL_DIRECTIONS.fetch(dir) do
                  Constants::INTERCARDINAL_DIRECTIONS.fetch(dir) do
                    raise ArgumentError, "unknown direction: #{dir}"
                  end
                end
              end

              def validate_direction!(val)
                sym = val.to_sym
                return if Constants::CARDINAL_DIRECTIONS.key?(sym) ||
                          Constants::INTERCARDINAL_DIRECTIONS.key?(sym)

                raise ArgumentError,
                      "unknown direction: #{val.inspect}; must be cardinal or intercardinal"
              end
            end
          end
        end
      end
    end
  end
end
