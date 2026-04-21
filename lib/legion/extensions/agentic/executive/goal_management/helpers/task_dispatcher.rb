# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            class TaskDispatcher
              DOMAIN_RUNNERS = {
                safety:        { runner_class: 'Legion::Extensions::MindGrowth::Runners::Monitor',
                                 function:     :health_check,
                                 args_builder: ->(goal) { { extension: goal[:domain].to_s } } },
                cognition:     { runner_class: 'Legion::Extensions::MindGrowth::Runners::Analyzer',
                                 function:     :recommend_priorities,
                                 args_builder: ->(_goal) { { existing_extensions: [] } } },
                perception:    { client_class: 'Legion::Extensions::Agentic::Learning::Curiosity::Client',
                                 function:     :detect_gaps,
                                 args_builder: ->(_goal) { { prior_results: {} } } },
                introspection: { client_class: 'Legion::Extensions::Agentic::Executive::Volition::Client',
                                 function:     :volition_status,
                                 args_builder: ->(_goal) { {} } }
              }.freeze

              def dispatch_goal(goal:)
                domain  = goal[:domain]&.to_sym
                mapping = DOMAIN_RUNNERS[domain]

                return unroutable(goal, domain) unless mapping
                return unroutable(goal, domain) unless runner_class_loaded?(mapping)

                execute_dispatch(goal: goal, mapping: mapping)
              rescue StandardError => e
                log.error "[task_dispatcher] dispatch error goal=#{goal[:id]} #{e.message}"
                { dispatched: false, error: e.message, goal_id: goal[:id] }
              end

              private

              def runner_class_loaded?(mapping)
                class_name = mapping[:runner_class] || mapping[:client_class]
                Kernel.const_get(class_name)
                true
              rescue NameError
                false
              end

              def execute_dispatch(goal:, mapping:)
                function = mapping[:function]
                args     = mapping[:args_builder].call(goal)

                result = if mapping.key?(:client_class)
                           dispatch_via_client(mapping[:client_class], function, args)
                         else
                           dispatch_via_runner(mapping[:runner_class], function, args)
                         end

                success    = result[:status] == 'task.completed'
                task_id    = result[:task_id]
                runner_key = mapping[:runner_class] || mapping[:client_class]

                log.info "[task_dispatcher] dispatched goal=#{goal[:id]} runner=#{runner_key} function=#{function}"

                {
                  dispatched:     true,
                  success:        success,
                  task_id:        task_id,
                  runner_mapping: runner_key,
                  result:         result,
                  goal_id:        goal[:id]
                }
              end

              def dispatch_via_runner(runner_class, function, args)
                Legion::Runner.run(
                  runner_class:  runner_class,
                  function:      function,
                  args:          args,
                  generate_task: true,
                  check_subtask: true
                )
              end

              def dispatch_via_client(client_class, function, args)
                client = Kernel.const_get(client_class).new
                client.send(function, **args)
              end

              def log
                Legion::Logging
              end

              def unroutable(goal, domain)
                log.debug "[task_dispatcher] no runner for domain=#{domain} goal=#{goal[:id]}"
                { dispatched: false, reason: :no_runner, domain: domain, goal_id: goal[:id] }
              end
            end
          end
        end
      end
    end
  end
end
