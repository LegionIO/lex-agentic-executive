# frozen_string_literal: true

require 'legion/extensions/agentic/executive/prospective_memory/helpers/constants'
require 'legion/extensions/agentic/executive/prospective_memory/helpers/intention'
require 'legion/extensions/agentic/executive/prospective_memory/helpers/prospective_engine'
require 'legion/extensions/agentic/executive/prospective_memory/runners/prospective_memory'

module Legion
  module Extensions
    module Agentic
      module Executive
        module ProspectiveMemory
          class Client
            include Runners::ProspectiveMemory

            def initialize(**)
              @prospective_engine = Helpers::ProspectiveEngine.new
            end

            private

            attr_reader :prospective_engine
          end
        end
      end
    end
  end
end
