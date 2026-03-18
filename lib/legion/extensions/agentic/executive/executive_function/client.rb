# frozen_string_literal: true

require 'legion/extensions/agentic/executive/executive_function/helpers/ef_component'
require 'legion/extensions/agentic/executive/executive_function/helpers/executive_controller'
require 'legion/extensions/agentic/executive/executive_function/runners/executive_function'

module Legion
  module Extensions
    module Agentic
      module Executive
        module ExecutiveFunction
          class Client
            include Runners::ExecutiveFunction

            def initialize(**)
              @controller = Helpers::ExecutiveController.new
            end

            private

            attr_reader :controller
          end
        end
      end
    end
  end
end
