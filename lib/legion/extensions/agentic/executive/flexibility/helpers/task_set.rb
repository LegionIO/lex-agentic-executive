# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Flexibility
          module Helpers
            class TaskSet
              include Constants

              attr_reader :id, :name, :domain, :rules, :created_at, :use_count
              attr_accessor :activation

              def initialize(id:, name:, domain: :general, activation: 0.5)
                @id         = id
                @name       = name
                @domain     = domain
                @rules      = []
                @activation = activation.to_f.clamp(0.0, 1.0)
                @created_at = Time.now.utc
                @use_count  = 0
              end

              def add_rule(type:, condition:, action:)
                return nil unless RULE_TYPES.include?(type)
                return nil if @rules.size >= MAX_RULES_PER_SET

                rule = { type: type, condition: condition, action: action }
                @rules << rule
                rule
              end

              def activate(amount = 0.2)
                @activation = [@activation + amount, 1.0].min
                @use_count += 1
              end

              def deactivate(amount = 0.2)
                @activation = [@activation - amount, 0.0].max
              end

              def active?
                @activation >= 0.5
              end

              def dominant?
                @activation >= PERSEVERATION_THRESHOLD
              end

              def to_h
                {
                  id:         @id,
                  name:       @name,
                  domain:     @domain,
                  activation: @activation.round(4),
                  active:     active?,
                  dominant:   dominant?,
                  rule_count: @rules.size,
                  use_count:  @use_count
                }
              end
            end
          end
        end
      end
    end
  end
end
