# frozen_string_literal: true

require 'legion/extensions/agentic/executive/flexibility_training/helpers/constants'
require 'legion/extensions/agentic/executive/flexibility_training/helpers/training_task'
require 'legion/extensions/agentic/executive/flexibility_training/helpers/switch_trial'
require 'legion/extensions/agentic/executive/flexibility_training/helpers/flexibility_engine'
require 'legion/extensions/agentic/executive/flexibility_training/runners/cognitive_flexibility_training'

module Legion
  module Extensions
    module Agentic
      module Executive
        module FlexibilityTraining
          class Client
            include Runners::CognitiveFlexibilityTraining

            def initialize(engine: nil, **)
              @flexibility_engine = engine || Helpers::FlexibilityEngine.new
            end

            private

            attr_reader :flexibility_engine
          end
        end
      end
    end
  end
end
