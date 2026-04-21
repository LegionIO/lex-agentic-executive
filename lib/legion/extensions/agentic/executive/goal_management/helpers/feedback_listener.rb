# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            class FeedbackListener
              def initialize(engine:)
                @engine    = engine
                @listening = false
              end

              def handle_task_event(task_id:, status:, result: nil)
                update = @engine.update_from_task_event(task_id: task_id, status: status, result: result)
                goal_id = update[:goal_id] if update.is_a?(Hash)
                log.info "[feedback_listener] task event task_id=#{task_id} goal_id=#{goal_id} new_status=#{status}"
                update
              end

              def start_listening
                return if @listening
                return unless defined?(Legion::Events)

                Legion::Events.on('task.completed') do |event|
                  handle_task_event(
                    task_id: event[:task_id],
                    status:  event[:status] || 'task.completed',
                    result:  event[:result]
                  )
                end

                Legion::Events.on('task.failed') do |event|
                  handle_task_event(
                    task_id: event[:task_id],
                    status:  event[:status] || 'task.failed',
                    result:  event[:result]
                  )
                end

                @listening = true
              end

              def listening?
                @listening
              end

              private

              def log
                Legion::Logging
              end
            end
          end
        end
      end
    end
  end
end
