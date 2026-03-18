# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module ProspectiveMemory
          module Helpers
            class Intention
              attr_reader :id, :description, :trigger_type, :trigger_condition,
                          :domain, :created_at, :triggered_at, :executed_at, :expires_at, :status

              attr_accessor :urgency

              def initialize(description:, trigger_type:, trigger_condition:, urgency: Constants::DEFAULT_URGENCY,
                             domain: nil, expires_at: nil)
                @id                = SecureRandom.uuid
                @description       = description
                @trigger_type      = trigger_type
                @trigger_condition = trigger_condition
                @urgency           = urgency.clamp(0.0, 1.0)
                @domain            = domain
                @status            = :pending
                @created_at        = Time.now.utc
                @triggered_at      = nil
                @executed_at       = nil
                @expires_at        = expires_at
              end

              def monitor!
                @status = :monitoring
              end

              def trigger!
                @status       = :triggered
                @triggered_at = Time.now.utc
              end

              def execute!
                @status      = :executed
                @executed_at = Time.now.utc
              end

              def expire!
                @status = :expired
              end

              def cancel!
                @status = :cancelled
              end

              def expired?
                return false unless @expires_at

                Time.now.utc > @expires_at
              end

              def boost_urgency!(amount: Constants::URGENCY_BOOST)
                @urgency = (@urgency + amount).clamp(0.0, 1.0).round(10)
              end

              def decay_urgency!
                @urgency = (@urgency - Constants::URGENCY_DECAY).clamp(0.0, 1.0).round(10)
              end

              def urgency_label
                Constants::URGENCY_LABELS.find { |range, _label| range.cover?(@urgency) }&.last || :deferred
              end

              def to_h
                {
                  id:                @id,
                  description:       @description,
                  trigger_type:      @trigger_type,
                  trigger_condition: @trigger_condition,
                  urgency:           @urgency,
                  urgency_label:     urgency_label,
                  status:            @status,
                  domain:            @domain,
                  created_at:        @created_at,
                  triggered_at:      @triggered_at,
                  executed_at:       @executed_at,
                  expires_at:        @expires_at
                }
              end
            end
          end
        end
      end
    end
  end
end
