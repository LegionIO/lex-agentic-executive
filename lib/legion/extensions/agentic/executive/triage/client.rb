# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Triage
          class Client
            include Runners::CognitiveTriage

            def initialize(engine: nil)
              @default_engine = engine || Helpers::TriageEngine.new
            end
          end
        end
      end
    end
  end
end
