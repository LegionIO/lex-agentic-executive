# frozen_string_literal: true

require 'legion/extensions/agentic/executive/planning/helpers/constants'
require 'legion/extensions/agentic/executive/planning/helpers/plan_step'
require 'legion/extensions/agentic/executive/planning/helpers/plan'
require 'legion/extensions/agentic/executive/planning/helpers/plan_store'
require 'legion/extensions/agentic/executive/planning/runners/planning'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Planning
          class Client
            include Runners::Planning

            attr_reader :plan_store

            def initialize(plan_store: nil, **)
              @plan_store = plan_store || Helpers::PlanStore.new
            end
          end
        end
      end
    end
  end
end
