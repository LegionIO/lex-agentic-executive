# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module DissonanceResolution
          module Helpers
            class DissonanceConflict
              include Constants

              attr_reader :id, :belief_a, :belief_b, :domain, :tension,
                          :strategy_used, :outcome, :attempts, :created_at, :resolved_at

              def initialize(belief_a:, belief_b:, domain: :general, tension: DEFAULT_TENSION)
                @id            = SecureRandom.uuid
                @belief_a      = belief_a
                @belief_b      = belief_b
                @domain        = domain.to_sym
                @tension       = tension.to_f.clamp(0.0, 1.0)
                @strategy_used = nil
                @outcome       = :ongoing
                @attempts      = 0
                @created_at    = Time.now.utc
                @resolved_at   = nil
              end

              def tension_label
                match = TENSION_LABELS.find { |range, _| range.cover?(@tension) }
                match ? match.last : :resolved
              end

              def resolved?
                @tension <= RESOLUTION_THRESHOLD
              end

              def apply_strategy!(strategy:, effectiveness: 0.3)
                @strategy_used = strategy.to_sym
                @attempts += 1
                reduction = effectiveness.to_f.clamp(0.0, 0.5)
                @tension = (@tension - reduction).clamp(0.0, 1.0).round(10)
                @outcome = :resolved if resolved?
                @resolved_at = Time.now.utc if resolved?
                self
              end

              def escalate!(amount: 0.15)
                @tension = (@tension + amount).clamp(0.0, 1.0).round(10)
                @outcome = :escalated if @tension >= 0.9
                self
              end

              def decay!
                @tension = (@tension - TENSION_DECAY).clamp(0.0, 1.0).round(10)
                @outcome = :resolved if resolved? && @outcome == :ongoing
                @resolved_at = Time.now.utc if resolved? && @resolved_at.nil?
                self
              end

              def abandon!
                @outcome = :abandoned
                @resolved_at = Time.now.utc
                self
              end

              def to_h
                {
                  id:            @id,
                  belief_a:      @belief_a,
                  belief_b:      @belief_b,
                  domain:        @domain,
                  tension:       @tension,
                  tension_label: tension_label,
                  resolved:      resolved?,
                  strategy_used: @strategy_used,
                  outcome:       @outcome,
                  attempts:      @attempts,
                  created_at:    @created_at,
                  resolved_at:   @resolved_at
                }
              end
            end
          end
        end
      end
    end
  end
end
