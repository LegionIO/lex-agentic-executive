# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Triage
          module Helpers
            class Demand
              include Constants

              attr_reader :id, :description, :domain, :severity, :urgency,
                          :triage_score, :status, :created_at, :triaged_at

              def initialize(description:, domain: :general, severity: :moderate, urgency: :soon)
                @id           = SecureRandom.uuid
                @description  = description
                @domain       = domain.to_sym
                @severity     = validate_level(severity, SEVERITY_LEVELS, :moderate)
                @urgency      = validate_level(urgency, URGENCY_LEVELS, :soon)
                @triage_score = compute_triage_score
                @status       = :pending
                @created_at   = Time.now.utc
                @triaged_at   = nil
              end

              def triage!
                @status = :triaged
                @triaged_at = Time.now.utc
                self
              end

              def defer!
                @status = :deferred
                self
              end

              def process!
                @status = :processing
                self
              end

              def complete!
                @status = :completed
                self
              end

              def drop!
                @status = :dropped
                self
              end

              def active?
                %i[pending triaged processing].include?(@status)
              end

              def triage_label
                Constants.label_for(TRIAGE_LABELS, @triage_score)
              end

              def red?
                @triage_score >= 0.8
              end

              def to_h
                {
                  id:           @id,
                  description:  @description,
                  domain:       @domain,
                  severity:     @severity,
                  urgency:      @urgency,
                  triage_score: @triage_score,
                  triage_label: triage_label,
                  status:       @status,
                  red:          red?,
                  created_at:   @created_at,
                  triaged_at:   @triaged_at
                }
              end

              private

              def validate_level(level, valid_levels, default)
                sym = level.to_sym
                valid_levels.include?(sym) ? sym : default
              end

              def compute_triage_score
                sev = SEVERITY_WEIGHTS.fetch(@severity, 0.5)
                urg = URGENCY_WEIGHTS.fetch(@urgency, 0.5)
                ((sev * 0.6) + (urg * 0.4)).round(10)
              end
            end
          end
        end
      end
    end
  end
end
