# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Compass
          module Helpers
            class MagneticBias
              attr_reader :id, :bias_type, :domain, :detected_at
              attr_accessor :declination, :strength

              def initialize(bias_type:, domain:, declination: nil, strength: nil)
                validate_bias!(bias_type)
                @id           = SecureRandom.uuid
                @bias_type    = bias_type.to_sym
                @domain       = domain.to_sym
                @declination  = (declination || 0.3).to_f.clamp(0.0, 1.0).round(10)
                @strength     = (strength || 0.5).to_f.clamp(0.0, 1.0).round(10)
                @detected_at  = Time.now.utc
              end

              def correct!(amount: Constants::CALIBRATION_BOOST)
                @declination = (@declination - amount.abs).clamp(0.0, 1.0).round(10)
                self
              end

              def intensify!(amount: 0.1)
                @strength = (@strength + amount.abs).clamp(0.0, 1.0).round(10)
                @declination = (@declination + (amount.abs * 0.5)).clamp(0.0, 1.0).round(10)
                self
              end

              def decay!(rate: Constants::DECLINATION_DECAY)
                @strength = (@strength - rate.abs).clamp(0.0, 1.0).round(10)
                @declination = (@declination - (rate.abs * 0.5)).clamp(0.0, 1.0).round(10)
                self
              end

              def severe?
                @declination >= 0.8
              end

              def negligible?
                @declination < 0.2
              end

              def declination_label
                Constants.label_for(Constants::DECLINATION_LABELS, @declination)
              end

              def to_h
                {
                  id:                @id,
                  bias_type:         @bias_type,
                  domain:            @domain,
                  declination:       @declination,
                  declination_label: declination_label,
                  strength:          @strength,
                  severe:            severe?,
                  negligible:        negligible?,
                  detected_at:       @detected_at
                }
              end

              private

              def validate_bias!(val)
                return if Constants::BIAS_TYPES.include?(val.to_sym)

                raise ArgumentError,
                      "unknown bias type: #{val.inspect}; " \
                      "must be one of #{Constants::BIAS_TYPES.inspect}"
              end
            end
          end
        end
      end
    end
  end
end
