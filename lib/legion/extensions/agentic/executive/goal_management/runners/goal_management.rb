# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Runners
            module GoalManagement
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def add_goal(content:, parent_id: nil, domain: :general,
                           priority: Helpers::Constants::DEFAULT_PRIORITY, deadline: nil, **)
                Legion::Logging.debug "[goal_management] runner add_goal domain=#{domain}"
                engine.add_goal(content: content, parent_id: parent_id, domain: domain,
                                priority: priority, deadline: deadline)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] add_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def decompose_goal(goal_id:, sub_goals:, **)
                Legion::Logging.debug "[goal_management] runner decompose_goal parent=#{goal_id}"
                engine.decompose(goal_id: goal_id, sub_goals: sub_goals)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] decompose_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def activate_goal(goal_id:, **)
                Legion::Logging.debug "[goal_management] runner activate_goal id=#{goal_id}"
                engine.activate_goal(goal_id: goal_id)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] activate_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def complete_goal(goal_id:, **)
                Legion::Logging.debug "[goal_management] runner complete_goal id=#{goal_id}"
                engine.complete_goal(goal_id: goal_id)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] complete_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def abandon_goal(goal_id:, **)
                Legion::Logging.debug "[goal_management] runner abandon_goal id=#{goal_id}"
                engine.abandon_goal(goal_id: goal_id)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] abandon_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def block_goal(goal_id:, **)
                Legion::Logging.debug "[goal_management] runner block_goal id=#{goal_id}"
                engine.block_goal(goal_id: goal_id)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] block_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def unblock_goal(goal_id:, **)
                Legion::Logging.debug "[goal_management] runner unblock_goal id=#{goal_id}"
                engine.unblock_goal(goal_id: goal_id)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] unblock_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def advance_goal_progress(goal_id:, amount:, **)
                Legion::Logging.debug "[goal_management] runner advance_goal_progress id=#{goal_id} amount=#{amount}"
                engine.advance_progress(goal_id: goal_id, amount: amount)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] advance_goal_progress error: #{e.message}"
                { success: false, error: e.message }
              end

              def detect_goal_conflicts(goal_id:, **)
                Legion::Logging.debug "[goal_management] runner detect_goal_conflicts id=#{goal_id}"
                engine.detect_conflicts(goal_id: goal_id)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] detect_goal_conflicts error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_active_goals(**)
                goals = engine.active_goals
                Legion::Logging.debug "[goal_management] list_active_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                Legion::Logging.error "[goal_management] list_active_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_blocked_goals(**)
                goals = engine.blocked_goals
                Legion::Logging.debug "[goal_management] list_blocked_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                Legion::Logging.error "[goal_management] list_blocked_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_overdue_goals(**)
                goals = engine.overdue_goals
                Legion::Logging.debug "[goal_management] list_overdue_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                Legion::Logging.error "[goal_management] list_overdue_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_completed_goals(**)
                goals = engine.completed_goals
                Legion::Logging.debug "[goal_management] list_completed_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                Legion::Logging.error "[goal_management] list_completed_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def get_goal_tree(goal_id:, **)
                Legion::Logging.debug "[goal_management] runner get_goal_tree id=#{goal_id}"
                engine.goal_tree(goal_id: goal_id)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] get_goal_tree error: #{e.message}"
                { success: false, error: e.message }
              end

              def highest_priority_goals(limit: 5, **)
                goals = engine.highest_priority(limit: limit)
                Legion::Logging.debug "[goal_management] highest_priority_goals limit=#{limit} count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                Legion::Logging.error "[goal_management] highest_priority_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def decay_priorities(**)
                result = engine.decay_all_priorities!
                Legion::Logging.debug "[goal_management] decay_priorities decayed=#{result[:decayed]}"
                result.merge(success: true)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] decay_priorities error: #{e.message}"
                { success: false, error: e.message }
              end

              def goal_status(**)
                report = engine.goal_report
                Legion::Logging.debug "[goal_management] goal_status total=#{report[:total]}"
                { success: true }.merge(report)
              rescue StandardError => e
                Legion::Logging.error "[goal_management] goal_status error: #{e.message}"
                { success: false, error: e.message }
              end

              private

              def engine
                @engine ||= Helpers::GoalEngine.new
              end
            end
          end
        end
      end
    end
  end
end
