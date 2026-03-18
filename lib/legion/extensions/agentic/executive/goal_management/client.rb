# frozen_string_literal: true

require 'legion/extensions/agentic/executive/goal_management/helpers/constants'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal_engine'
require 'legion/extensions/agentic/executive/goal_management/runners/goal_management'

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          class Client
            include Runners::GoalManagement

            def initialize(**)
              @engine = Helpers::GoalEngine.new
            end

            private

            attr_reader :engine
          end
        end
      end
    end
  end
end
