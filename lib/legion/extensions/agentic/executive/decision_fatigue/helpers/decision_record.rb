# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module DecisionFatigue
          module Helpers
            class DecisionRecord
              attr_reader :id, :label, :decision_type, :complexity,
                          :quality_at_time, :willpower_cost, :created_at

              def initialize(id:, label:, decision_type:, complexity:, quality_at_time:, willpower_cost:)
                @id              = id
                @label           = label
                @decision_type   = decision_type
                @complexity      = complexity.clamp(0.0, 1.0)
                @quality_at_time = quality_at_time.clamp(Constants::QUALITY_FLOOR, 1.0)
                @willpower_cost  = willpower_cost
                @created_at      = Time.now.utc
              end

              def complexity_label
                Constants.complexity_label_for(@complexity)
              end

              def quality_label
                Constants.quality_label_for(@quality_at_time)
              end

              def to_h
                {
                  id:               @id,
                  label:            @label,
                  decision_type:    @decision_type,
                  complexity:       @complexity,
                  complexity_label: complexity_label,
                  quality_at_time:  @quality_at_time,
                  quality_label:    quality_label,
                  willpower_cost:   @willpower_cost,
                  created_at:       @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
