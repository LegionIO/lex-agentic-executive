# frozen_string_literal: true

require 'legion/extensions/agentic/executive/load/helpers/constants'
require 'legion/extensions/agentic/executive/load/helpers/load_model'
require 'legion/extensions/agentic/executive/load/runners/cognitive_load'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Load
          class Client
            include Runners::CognitiveLoad

            attr_reader :load_model

            def initialize(load_model: nil, **)
              @load_model = load_model || Helpers::LoadModel.new
            end
          end
        end
      end
    end
  end
end
