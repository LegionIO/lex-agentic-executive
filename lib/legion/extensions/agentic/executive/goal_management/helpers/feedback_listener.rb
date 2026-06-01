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
                @handlers  = []
              end

              def handle_task_event(task_id:, status:, result: nil)
                update = @engine.update_from_task_event(task_id: task_id, status: status, result: result)
                goal_id = update[:goal_id] if update.is_a?(Hash)
                new_status = update[:new_status] if update.is_a?(Hash)
                unhandled_status = update[:unhandled_status] if update.is_a?(Hash)
                log.info "[feedback_listener] task event task_id=#{task_id} goal_id=#{goal_id} " \
                         "task_status=#{status} new_status=#{new_status} unhandled_status=#{unhandled_status}"
                update
              end

              def start_listening
                return if @listening
                return unless defined?(Legion::Events)

                handler_completed = Legion::Events.on('task.completed') do |event|
                  handle_task_event(
                    task_id: event[:task_id],
                    status:  event[:status] || 'task.completed',
                    result:  event[:result]
                  )
                end

                handler_failed = Legion::Events.on('task.failed') do |event|
                  handle_task_event(
                    task_id: event[:task_id],
                    status:  event[:status] || 'task.failed',
                    result:  event[:result]
                  )
                end

                @handlers << { event: 'task.completed', block: handler_completed }
                @handlers << { event: 'task.failed', block: handler_failed }
                @listening = true
              end

              def stop_listening
                return unless @listening

                @handlers.each do |entry|
                  Legion::Events.off(entry[:event], entry[:block])
                rescue StandardError
                  # swallow — listener already removed or Events unavailable
                end
                @handlers.clear
                @listening = false
              end

              def restart_listening
                stop_listening
                start_listening
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
