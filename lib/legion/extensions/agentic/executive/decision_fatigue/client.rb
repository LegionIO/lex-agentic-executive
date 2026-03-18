# frozen_string_literal: true

require 'legion/extensions/agentic/executive/decision_fatigue/helpers/constants'
require 'legion/extensions/agentic/executive/decision_fatigue/helpers/decision_record'
require 'legion/extensions/agentic/executive/decision_fatigue/helpers/fatigue_engine'
require 'legion/extensions/agentic/executive/decision_fatigue/runners/decision_fatigue'

module Legion
  module Extensions
    module Agentic
      module Executive
        module DecisionFatigue
          class Client
            include Runners::DecisionFatigue

            def initialize(**)
              @fatigue_engine = Helpers::FatigueEngine.new
            end

            private

            attr_reader :fatigue_engine
          end
        end
      end
    end
  end
end
