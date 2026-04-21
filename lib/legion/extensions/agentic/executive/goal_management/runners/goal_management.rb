# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Runners
            module GoalManagement
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def add_goal(content:, parent_id: nil, domain: :general,
                           priority: Helpers::Constants::DEFAULT_PRIORITY, deadline: nil, **)
                log.debug "[goal_management] runner add_goal domain=#{domain}"
                engine.add_goal(content: content, parent_id: parent_id, domain: domain,
                                priority: priority, deadline: deadline)
              rescue StandardError => e
                log.error "[goal_management] add_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def decompose_goal(goal_id:, sub_goals:, **)
                log.debug "[goal_management] runner decompose_goal parent=#{goal_id}"
                engine.decompose(goal_id: goal_id, sub_goals: sub_goals)
              rescue StandardError => e
                log.error "[goal_management] decompose_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def auto_decompose_goal(goal_id:, strategy: :heuristic, **)
                goal_data = engine.goals[goal_id]
                return { success: false, error: :not_found } unless goal_data

                decomp = Helpers::Decomposer.decompose(goal: goal_data.to_h, strategy: strategy)
                return decomp unless decomp[:success]

                result = engine.decompose(goal_id: goal_id, sub_goals: decomp[:sub_goals])
                result.merge(strategy_used: decomp[:strategy_used])
              rescue StandardError => e
                log.error "[goal_management] auto_decompose_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def activate_goal(goal_id:, **)
                log.debug "[goal_management] runner activate_goal id=#{goal_id}"
                engine.activate_goal(goal_id: goal_id)
              rescue StandardError => e
                log.error "[goal_management] activate_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def complete_goal(goal_id:, **)
                log.debug "[goal_management] runner complete_goal id=#{goal_id}"
                engine.complete_goal(goal_id: goal_id)
              rescue StandardError => e
                log.error "[goal_management] complete_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def abandon_goal(goal_id:, **)
                log.debug "[goal_management] runner abandon_goal id=#{goal_id}"
                engine.abandon_goal(goal_id: goal_id)
              rescue StandardError => e
                log.error "[goal_management] abandon_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def block_goal(goal_id:, **)
                log.debug "[goal_management] runner block_goal id=#{goal_id}"
                engine.block_goal(goal_id: goal_id)
              rescue StandardError => e
                log.error "[goal_management] block_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def unblock_goal(goal_id:, **)
                log.debug "[goal_management] runner unblock_goal id=#{goal_id}"
                engine.unblock_goal(goal_id: goal_id)
              rescue StandardError => e
                log.error "[goal_management] unblock_goal error: #{e.message}"
                { success: false, error: e.message }
              end

              def advance_goal_progress(goal_id:, amount:, **)
                log.debug "[goal_management] runner advance_goal_progress id=#{goal_id} amount=#{amount}"
                engine.advance_progress(goal_id: goal_id, amount: amount)
              rescue StandardError => e
                log.error "[goal_management] advance_goal_progress error: #{e.message}"
                { success: false, error: e.message }
              end

              def detect_goal_conflicts(goal_id:, **)
                log.debug "[goal_management] runner detect_goal_conflicts id=#{goal_id}"
                engine.detect_conflicts(goal_id: goal_id)
              rescue StandardError => e
                log.error "[goal_management] detect_goal_conflicts error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_active_goals(**)
                goals = engine.active_goals
                log.debug "[goal_management] list_active_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                log.error "[goal_management] list_active_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_blocked_goals(**)
                goals = engine.blocked_goals
                log.debug "[goal_management] list_blocked_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                log.error "[goal_management] list_blocked_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_overdue_goals(**)
                goals = engine.overdue_goals
                log.debug "[goal_management] list_overdue_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                log.error "[goal_management] list_overdue_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def list_completed_goals(**)
                goals = engine.completed_goals
                log.debug "[goal_management] list_completed_goals count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                log.error "[goal_management] list_completed_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def get_goal_tree(goal_id:, **)
                log.debug "[goal_management] runner get_goal_tree id=#{goal_id}"
                engine.goal_tree(goal_id: goal_id)
              rescue StandardError => e
                log.error "[goal_management] get_goal_tree error: #{e.message}"
                { success: false, error: e.message }
              end

              def highest_priority_goals(limit: 5, **)
                goals = engine.highest_priority(limit: limit)
                log.debug "[goal_management] highest_priority_goals limit=#{limit} count=#{goals.size}"
                { success: true, goals: goals.map(&:to_h), count: goals.size }
              rescue StandardError => e
                log.error "[goal_management] highest_priority_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def decay_priorities(**)
                result = engine.decay_all_priorities!
                log.debug "[goal_management] decay_priorities decayed=#{result[:decayed]}"
                result.merge(success: true)
              rescue StandardError => e
                log.error "[goal_management] decay_priorities error: #{e.message}"
                { success: false, error: e.message }
              end

              def goal_status(**)
                report = engine.goal_report
                log.debug "[goal_management] goal_status total=#{report[:total]}"
                { success: true }.merge(report)
              rescue StandardError => e
                log.error "[goal_management] goal_status error: #{e.message}"
                { success: false, error: e.message }
              end

              def dispatch_leaf_goals(**)
                dispatcher = Helpers::TaskDispatcher.new
                engine.goals.each_value do |g|
                  g.activate! if g.leaf? && g.status == :proposed
                end
                leaves  = engine.active_goals.select(&:leaf?)
                results = leaves.reject(&:task_id).map do |goal|
                  dispatch = dispatcher.dispatch_goal(goal: goal.to_h)
                  goal.assign_task!(task_id: dispatch[:task_id], runner_mapping: dispatch[:runner_mapping]) if dispatch[:dispatched] && dispatch[:task_id]
                  { goal_id: goal.id, dispatch: dispatch }
                end
                dispatched_count = results.count { |r| r[:dispatch][:dispatched] }
                log.debug "[goal_management] dispatch_leaf_goals dispatched=#{dispatched_count} total=#{results.size}"
                { success: true, dispatched: dispatched_count, total: results.size, results: results }
              rescue StandardError => e
                log.error "[goal_management] dispatch_leaf_goals error: #{e.message}"
                { success: false, error: e.message }
              end

              def update_goal_from_task(task_id:, status:, result: nil, **)
                engine.update_from_task_event(task_id: task_id, status: status, result: result)
              rescue StandardError => e
                log.error "[goal_management] update_goal_from_task error: #{e.message}"
                { success: false, error: e.message }
              end

              def start_feedback_listener(**)
                feedback_listener.start_listening
                { success: true, listening: feedback_listener.listening? }
              rescue StandardError => e
                log.error "[goal_management] start_feedback_listener error: #{e.message}"
                { success: false, error: e.message }
              end

              private

              def engine
                @engine ||= Helpers::GoalEngine.new
              end

              def feedback_listener
                @feedback_listener ||= Helpers::FeedbackListener.new(engine: engine)
              end
            end
          end
        end
      end
    end
  end
end
