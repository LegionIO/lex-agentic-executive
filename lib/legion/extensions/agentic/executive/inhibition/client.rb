# frozen_string_literal: true

require 'legion/extensions/agentic/executive/inhibition/helpers/constants'
require 'legion/extensions/agentic/executive/inhibition/helpers/impulse'
require 'legion/extensions/agentic/executive/inhibition/helpers/inhibition_model'
require 'legion/extensions/agentic/executive/inhibition/helpers/inhibition_store'
require 'legion/extensions/agentic/executive/inhibition/runners/inhibition'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inhibition
          class Client
            include Runners::Inhibition

            attr_reader :inhibition_store

            def initialize(inhibition_store: nil, **)
              @inhibition_store = inhibition_store || Helpers::InhibitionStore.new
            end
          end
        end
      end
    end
  end
end
