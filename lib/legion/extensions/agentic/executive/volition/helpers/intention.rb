# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          module Helpers
            module Intention
              module_function

              def new_intention(drive:, domain:, goal:, salience:, context: {})
                {
                  intention_id: SecureRandom.hex(8),
                  drive:        drive.to_sym,
                  domain:       domain.to_sym,
                  goal:         goal,
                  salience:     salience.clamp(0.0, 1.0),
                  state:        :active,
                  created_at:   Time.now.utc,
                  age_ticks:    0,
                  context:      context
                }
              end

              def decay(intention)
                new_salience = [intention[:salience] - Constants::INTENTION_DECAY, 0.0].max
                intention.merge(salience: new_salience, age_ticks: intention[:age_ticks] + 1)
              end

              def reinforce(intention, amount: 0.1)
                new_salience = [intention[:salience] + amount, 1.0].min
                intention.merge(salience: new_salience)
              end

              def expired?(intention)
                intention[:age_ticks] >= Constants::MAX_INTENTION_AGE ||
                  intention[:salience] < Constants::INTENTION_FLOOR
              end

              def active?(intention)
                intention[:state] == :active && !expired?(intention)
              end

              def drive_label(drive)
                Constants::DRIVE_LABELS[drive.to_sym] || drive.to_s
              end
            end
          end
        end
      end
    end
  end
end
