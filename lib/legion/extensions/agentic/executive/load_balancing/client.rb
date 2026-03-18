# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module LoadBalancing
          class Client
            include Runners::CognitiveLoadBalancing

            def engine
              @engine ||= Helpers::LoadBalancer.new
            end
          end
        end
      end
    end
  end
end
