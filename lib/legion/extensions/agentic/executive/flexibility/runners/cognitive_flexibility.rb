# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Flexibility
          module Runners
            module CognitiveFlexibility
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def create_task_set(name:, domain: :general, **)
                Legion::Logging.debug "[cognitive_flexibility] create: #{name}"
                ts = engine.create_task_set(name: name, domain: domain)
                ts ? { success: true, task_set: ts.to_h } : { success: false, reason: :limit_reached }
              end

              def add_rule(set_id:, type:, condition:, action:, **)
                Legion::Logging.debug "[cognitive_flexibility] rule: set=#{set_id} type=#{type}"
                rule = engine.add_rule(set_id: set_id.to_sym, type: type.to_sym, condition: condition, action: action)
                rule ? { success: true, rule: rule } : { success: false, reason: :invalid }
              end

              def switch_set(set_id:, **)
                Legion::Logging.debug "[cognitive_flexibility] switch to #{set_id}"
                ts = engine.switch_to(set_id: set_id.to_sym)
                if ts
                  { success: true, task_set: ts.to_h, switch_cost: engine.switch_cost.round(4) }
                else
                  { success: false, reason: :not_found }
                end
              end

              def current_task_set(**)
                cs = engine.current_set
                cs ? { success: true, task_set: cs.to_h } : { success: true, task_set: nil }
              end

              def available_sets(**)
                sets = engine.available_sets
                { success: true, sets: sets, count: sets.size }
              end

              def flexibility_level(**)
                {
                  success:       true,
                  flexibility:   engine.flexibility.round(4),
                  label:         engine.flexibility_label,
                  perseverating: engine.perseverating?,
                  switch_cost:   engine.switch_cost.round(4)
                }
              end

              def update_cognitive_flexibility(**)
                Legion::Logging.debug '[cognitive_flexibility] tick'
                engine.tick
                { success: true, switch_cost: engine.switch_cost.round(4) }
              end

              def cognitive_flexibility_stats(**)
                Legion::Logging.debug '[cognitive_flexibility] stats'
                { success: true, stats: engine.to_h }
              end

              private

              def engine
                @engine ||= Helpers::FlexibilityEngine.new
              end
            end
          end
        end
      end
    end
  end
end
