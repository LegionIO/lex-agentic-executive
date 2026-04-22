# frozen_string_literal: true

require 'legion/extensions/agentic/executive/goal_management/helpers/constants'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal_persistence'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal_engine'
require 'legion/extensions/agentic/executive/goal_management/helpers/task_dispatcher'
require 'legion/extensions/agentic/executive/goal_management/helpers/feedback_listener'
require 'legion/extensions/agentic/executive/goal_management/helpers/decomposer'
require 'legion/extensions/agentic/executive/goal_management/runners/goal_management'

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          class Client
            include Runners::GoalManagement

            LISTENER_MUTEX = Mutex.new
            private_constant :LISTENER_MUTEX

            @listener_started = false
            class << self
              attr_accessor :listener_started
            end

            def initialize(**)
              @engine = Helpers::GoalEngine.new
              @feedback_listener = Helpers::FeedbackListener.new(engine: @engine)
              start_listener_once
            end

            private

            attr_reader :engine

            def start_listener_once
              LISTENER_MUTEX.synchronize do
                return if self.class.listener_started

                @feedback_listener.start_listening
                self.class.listener_started = true
              end
            end
          end
        end
      end
    end
  end
end
