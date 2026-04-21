# frozen_string_literal: true

require 'legion/extensions/agentic/executive/goal_management/helpers/constants'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal_persistence'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal_engine'
require 'legion/extensions/agentic/executive/goal_management/helpers/task_dispatcher'
require 'legion/extensions/agentic/executive/goal_management/helpers/feedback_listener'
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
              @feedback_listener = Helpers::FeedbackListener.new(engine: @engine)
              @feedback_listener.start_listening
            end

            private

            attr_reader :engine
          end
        end
      end
    end
  end
end
