# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inertia
          module Helpers
            class Belief
              include Constants

              attr_reader :id, :content, :domain, :conviction, :inertia,
                          :challenges_resisted, :challenges_accepted, :created_at

              def initialize(content:, domain: :factual, conviction: 0.5)
                @id                  = SecureRandom.uuid
                @content             = content
                @domain              = domain.to_sym
                @conviction          = conviction.to_f.clamp(0.0, 1.0)
                @inertia             = DEFAULT_INERTIA
                @challenges_resisted = 0
                @challenges_accepted = 0
                @created_at          = Time.now.utc
              end

              def challenge!(strength: 0.5)
                effective = (strength * (1.0 - @inertia)).round(10)
                if effective > @conviction * 0.5
                  @conviction = (@conviction - (effective * 0.3)).clamp(0.0, 1.0).round(10)
                  @challenges_accepted += 1
                  @inertia = (@inertia - INERTIA_REDUCTION_RATE).clamp(0.0, 1.0).round(10)
                  :accepted
                else
                  @challenges_resisted += 1
                  @inertia = (@inertia + INERTIA_GROWTH_RATE).clamp(0.0, 1.0).round(10)
                  :resisted
                end
              end

              def reinforce!(amount: 0.1)
                @conviction = (@conviction + amount).clamp(0.0, 1.0).round(10)
                @inertia = (@inertia + INERTIA_GROWTH_RATE).clamp(0.0, 1.0).round(10)
                self
              end

              def entrenched?
                @inertia >= CONVICTION_THRESHOLD
              end

              def flexible?
                @inertia <= FLEXIBILITY_THRESHOLD
              end

              def total_challenges
                @challenges_resisted + @challenges_accepted
              end

              def resistance_rate
                return 0.0 if total_challenges.zero?

                (@challenges_resisted.to_f / total_challenges).round(4)
              end

              def inertia_label
                match = INERTIA_LABELS.find { |range, _| range.cover?(@inertia) }
                match ? match.last : :fluid
              end

              def conviction_label
                match = CONVICTION_LABELS.find { |range, _| range.cover?(@conviction) }
                match ? match.last : :uncertain
              end

              def to_h
                {
                  id:                  @id,
                  content:             @content,
                  domain:              @domain,
                  conviction:          @conviction,
                  conviction_label:    conviction_label,
                  inertia:             @inertia,
                  inertia_label:       inertia_label,
                  entrenched:          entrenched?,
                  flexible:            flexible?,
                  challenges_resisted: @challenges_resisted,
                  challenges_accepted: @challenges_accepted,
                  resistance_rate:     resistance_rate,
                  created_at:          @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
