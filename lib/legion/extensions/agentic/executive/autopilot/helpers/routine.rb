# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Autopilot
          module Helpers
            class Routine
              include Constants

              attr_reader :id, :pattern, :domain, :familiarity, :execution_count,
                          :success_count, :failure_count, :created_at, :last_executed_at

              def initialize(pattern:, domain: :routine, familiarity: 0.0)
                @id               = SecureRandom.uuid
                @pattern          = pattern
                @domain           = validate_domain(domain)
                @familiarity      = familiarity.to_f.clamp(0.0, 1.0).round(10)
                @execution_count  = 0
                @success_count    = 0
                @failure_count    = 0
                @created_at       = Time.now.utc
                @last_executed_at = nil
              end

              def execute!(success: true)
                @execution_count += 1
                @last_executed_at = Time.now.utc
                if success
                  @success_count += 1
                  @familiarity = (@familiarity + FAMILIARITY_BOOST).clamp(0.0, 1.0).round(10)
                else
                  @failure_count += 1
                  @familiarity = (@familiarity - FAMILIARITY_BOOST).clamp(0.0, 1.0).round(10)
                end
                self
              end

              def decay!
                @familiarity = (@familiarity - FAMILIARITY_DECAY).clamp(0.0, 1.0).round(10)
                self
              end

              def autopilot_ready?
                @familiarity >= AUTOPILOT_THRESHOLD
              end

              def novel?
                @familiarity <= DELIBERATE_THRESHOLD
              end

              def success_rate
                return 0.0 if @execution_count.zero?

                (@success_count.to_f / @execution_count).round(10)
              end

              def familiarity_label = Constants.label_for(FAMILIARITY_LABELS, @familiarity)

              def to_h
                {
                  id:                @id,
                  pattern:           @pattern,
                  domain:            @domain,
                  familiarity:       @familiarity,
                  familiarity_label: familiarity_label,
                  autopilot_ready:   autopilot_ready?,
                  novel:             novel?,
                  execution_count:   @execution_count,
                  success_rate:      success_rate,
                  created_at:        @created_at,
                  last_executed_at:  @last_executed_at
                }
              end

              private

              def validate_domain(domain)
                sym = domain.to_sym
                TASK_DOMAINS.include?(sym) ? sym : :unknown
              end
            end
          end
        end
      end
    end
  end
end
