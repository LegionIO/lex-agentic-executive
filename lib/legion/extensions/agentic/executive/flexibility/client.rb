# frozen_string_literal: true

require 'legion/extensions/agentic/executive/flexibility/helpers/constants'
require 'legion/extensions/agentic/executive/flexibility/helpers/task_set'
require 'legion/extensions/agentic/executive/flexibility/helpers/flexibility_engine'
require 'legion/extensions/agentic/executive/flexibility/runners/cognitive_flexibility'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Flexibility
          class Client
            include Runners::CognitiveFlexibility

            def initialize(engine: nil, **)
              @engine = engine || Helpers::FlexibilityEngine.new
            end

            private

            attr_reader :engine
          end
        end
      end
    end
  end
end
