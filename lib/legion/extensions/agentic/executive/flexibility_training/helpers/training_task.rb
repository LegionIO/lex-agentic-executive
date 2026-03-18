# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module FlexibilityTraining
          module Helpers
            class TrainingTask
              attr_reader :id, :name, :domain, :difficulty, :baseline_performance, :practice_count, :created_at

              def initialize(name:, domain:, difficulty:)
                @id                   = SecureRandom.uuid
                @name                 = name
                @domain               = domain
                @difficulty           = difficulty.clamp(0.0, 1.0).round(10)
                @baseline_performance = (1.0 - (@difficulty * 0.4)).clamp(0.0, 1.0).round(10)
                @practice_count       = 0
                @created_at           = Time.now.utc
              end

              def practice!
                @practice_count += 1
                improvement = (Constants::IMPROVEMENT_RATE / (1.0 + (@practice_count * 0.1))).round(10)
                @baseline_performance = [(@baseline_performance + improvement), 1.0].min.round(10)
                self
              end

              def difficulty_label
                index = (@difficulty * (Constants::DIFFICULTY_LEVELS.size - 1)).round
                Constants::DIFFICULTY_LEVELS[index]
              end

              def to_h
                {
                  id:                   @id,
                  name:                 @name,
                  domain:               @domain,
                  difficulty:           @difficulty,
                  baseline_performance: @baseline_performance,
                  practice_count:       @practice_count,
                  difficulty_label:     difficulty_label,
                  created_at:           @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
