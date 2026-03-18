# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Control
          class Client
            include Runners::CognitiveControl

            def initialize(controller: nil)
              @controller = controller || Helpers::Controller.new
            end
          end
        end
      end
    end
  end
end
