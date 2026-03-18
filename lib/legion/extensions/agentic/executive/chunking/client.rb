# frozen_string_literal: true

require 'legion/extensions/agentic/executive/chunking/runners/cognitive_chunking'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Chunking
          class Client
            include Runners::CognitiveChunking

            def initialize(**)
              @chunking_engine = Helpers::ChunkingEngine.new
            end
          end
        end
      end
    end
  end
end
