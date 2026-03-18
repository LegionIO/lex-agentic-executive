# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Control
          module Runners
            module CognitiveControl
              include Helpers::Constants
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def set_control_goal(description:, domain: :general, priority: 0.5, **)
                goal = controller.set_goal(description: description, domain: domain, priority: priority)
                return { success: false, reason: :limit_reached } unless goal

                { success: true, goal_id: goal.id, priority: goal.priority }
              end

              def advance_control_goal(goal_id:, amount: 0.1, **)
                result = controller.advance_goal(goal_id: goal_id, amount: amount)
                return { success: false, reason: :not_found } unless result

                { success: true, goal_id: goal_id, progress: result.round(4) }
              end

              def suspend_control_goal(goal_id:, **)
                controller.suspend_goal(goal_id: goal_id)
                { success: true, goal_id: goal_id }
              end

              def evaluate_control(conflict: false, error: false, novelty: false, **)
                result = controller.evaluate_control_demand(conflict: conflict, error: error, novelty: novelty)
                { success: true }.merge(result)
              end

              def current_control_mode(**)
                { success: true, mode: controller.current_mode, should_override: controller.should_override?,
                  should_control: controller.should_control? }
              end

              def active_control_goals(**)
                goals = controller.active_goals
                { success: true, goals: goals, count: goals.size }
              end

              def top_control_goal(**)
                goal = controller.top_goal
                return { success: false, reason: :no_active_goals } unless goal

                { success: true }.merge(goal)
              end

              def update_cognitive_control(**)
                result = controller.tick
                { success: true }.merge(result)
              end

              def cognitive_control_stats(**)
                { success: true }.merge(controller.to_h)
              end

              private

              def controller
                @controller ||= Helpers::Controller.new
              end
            end
          end
        end
      end
    end
  end
end
