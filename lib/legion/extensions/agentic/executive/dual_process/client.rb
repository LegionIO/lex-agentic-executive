# frozen_string_literal: true

require 'legion/extensions/agentic/executive/dual_process/helpers/constants'
require 'legion/extensions/agentic/executive/dual_process/helpers/heuristic'
require 'legion/extensions/agentic/executive/dual_process/helpers/decision'
require 'legion/extensions/agentic/executive/dual_process/helpers/dual_process_engine'
require 'legion/extensions/agentic/executive/dual_process/runners/dual_process'

module Legion
  module Extensions
    module Agentic
      module Executive
        module DualProcess
          class Client
            include Runners::DualProcess

            def initialize(engine: nil)
              @engine = engine || Helpers::DualProcessEngine.new
            end
          end
        end
      end
    end
  end
end
