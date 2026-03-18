# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module Agentic
      module Executive
        module ExecutiveFunction
          module Actor
            class Recovery < Legion::Extensions::Actors::Every
              def runner_class
                Legion::Extensions::Agentic::Executive::ExecutiveFunction::Runners::ExecutiveFunction
              end

              def runner_function
                'executive_function_stats'
              end

              def time
                30
              end

              def run_now?
                false
              end

              def use_runner?
                false
              end

              def check_subtask?
                false
              end

              def generate_task?
                false
              end
            end
          end
        end
      end
    end
  end
end
