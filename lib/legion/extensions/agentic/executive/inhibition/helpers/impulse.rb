# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inhibition
          module Helpers
            class Impulse
              attr_reader :id, :type, :action, :strength, :source, :context, :created_at

              def initialize(type:, action:, strength:, source: nil, context: {})
                @id         = SecureRandom.uuid
                @type       = type
                @action     = action
                @strength   = strength
                @source     = source
                @context    = context
                @created_at = Time.now.utc
              end

              def overwhelming?
                @strength >= Constants::IMPULSE_STRENGTHS[:strong]
              end

              def auto_suppressible?
                @strength <= Constants::AUTOMATIC_SUPPRESS_THRESHOLD
              end
            end
          end
        end
      end
    end
  end
end
