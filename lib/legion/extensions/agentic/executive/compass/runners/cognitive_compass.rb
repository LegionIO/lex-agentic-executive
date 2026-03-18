# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Compass
          module Runners
            module CognitiveCompass
              extend self

              def take_bearing(direction:, context:, confidence: nil, engine: nil, **)
                eng     = resolve_engine(engine)
                bearing = eng.take_bearing(direction: direction, context: context,
                                           confidence: confidence)
                { success: true, bearing: bearing.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def register_bias(bias_type:, domain:, declination: nil,
                                strength: nil, engine: nil, **)
                eng  = resolve_engine(engine)
                bias = eng.register_bias(bias_type: bias_type, domain: domain,
                                         declination: declination, strength: strength)
                { success: true, bias: bias.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def calibrate(bias_id:, amount: nil, engine: nil, **)
                eng  = resolve_engine(engine)
                opts = { bias_id: bias_id }
                opts[:amount] = amount if amount
                bias = eng.calibrate(**opts)
                { success: true, bias: bias.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def list_bearings(engine: nil, direction: nil, **)
                eng     = resolve_engine(engine)
                results = eng.all_bearings
                results = results.select { |b| b.direction == direction.to_sym } if direction
                { success: true, bearings: results.map(&:to_h), count: results.size }
              end

              def list_biases(engine: nil, **)
                eng = resolve_engine(engine)
                { success: true, biases: eng.all_biases.map(&:to_h),
                  count: eng.all_biases.size }
              end

              def compass_status(engine: nil, **)
                eng = resolve_engine(engine)
                { success: true, report: eng.compass_report }
              end

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              private

              def resolve_engine(engine)
                engine || default_engine
              end

              def default_engine
                @default_engine ||= Helpers::CompassEngine.new
              end
            end
          end
        end
      end
    end
  end
end
