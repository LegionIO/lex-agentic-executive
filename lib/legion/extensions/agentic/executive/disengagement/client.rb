# frozen_string_literal: true

require 'legion/extensions/agentic/executive/disengagement/helpers/constants'
require 'legion/extensions/agentic/executive/disengagement/helpers/goal'
require 'legion/extensions/agentic/executive/disengagement/helpers/disengagement_engine'
require 'legion/extensions/agentic/executive/disengagement/runners/cognitive_disengagement'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Disengagement
          class Client
            include Runners::CognitiveDisengagement

            def initialize(**)
              @engine = Helpers::DisengagementEngine.new
            end
          end
        end
      end
    end
  end
end
