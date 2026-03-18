# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Flexibility
          module Actors
            class Tick < Legion::Extensions::Actors::Every
              def time
                10
              end

              def use_runner?
                false
              end

              def runner_function
                :update_cognitive_flexibility
              end

              def runner_class
                Legion::Extensions::Agentic::Executive::Flexibility::Runners::CognitiveFlexibility
              end
            end
          end
        end
      end
    end
  end
end
