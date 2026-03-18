# frozen_string_literal: true

require 'securerandom'

require_relative 'compass/version'
require_relative 'compass/helpers/constants'
require_relative 'compass/helpers/bearing'
require_relative 'compass/helpers/magnetic_bias'
require_relative 'compass/helpers/compass_engine'
require_relative 'compass/runners/cognitive_compass'
require_relative 'compass/client'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Compass
        end
      end
    end
  end
end
