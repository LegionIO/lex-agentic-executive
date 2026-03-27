# frozen_string_literal: true

require_relative 'executive/version'
require_relative 'executive/control'
require_relative 'executive/flexibility'
require_relative 'executive/flexibility_training'
require_relative 'executive/load'
require_relative 'executive/load_balancing'
require_relative 'executive/disengagement'
require_relative 'executive/triage'
require_relative 'executive/chunking'
require_relative 'executive/inertia'
require_relative 'executive/dwell'
require_relative 'executive/autopilot'
require_relative 'executive/dissonance_resolution'
require_relative 'executive/compass'
require_relative 'executive/executive_function'
require_relative 'executive/goal_management'
require_relative 'executive/inhibition'
require_relative 'executive/planning'
require_relative 'executive/volition'
require_relative 'executive/working_memory'
require_relative 'executive/decision_fatigue'
require_relative 'executive/dual_process'
require_relative 'executive/prospective_memory'
require_relative 'executive/cognitive_debt'

module Legion
  module Extensions
    module Agentic
      module Executive
        extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core

        def self.remote_invocable?
          false
        end
      end
    end
  end
end
