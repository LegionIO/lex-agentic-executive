# frozen_string_literal: true

require 'legion/extensions/agentic/executive/volition/helpers/constants'
require 'legion/extensions/agentic/executive/volition/helpers/intention'
require 'legion/extensions/agentic/executive/volition/helpers/intention_stack'
require 'legion/extensions/agentic/executive/volition/helpers/drive_synthesizer'
require 'legion/extensions/agentic/executive/volition/runners/volition'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          class Client
            include Runners::Volition

            attr_reader :intention_stack

            def initialize(stack: nil, **)
              @intention_stack = stack || Helpers::IntentionStack.new
            end
          end
        end
      end
    end
  end
end
