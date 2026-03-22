# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Chunking
          module Helpers
            module Constants
              MAX_ITEMS               = 500
              MAX_CHUNKS              = 200
              WORKING_MEMORY_CAPACITY = 4    # Cowan (2001) core capacity
              CAPACITY_VARIANCE       = 2    # +/- 2
              DEFAULT_COHERENCE       = 0.5
              COHERENCE_BOOST         = 0.08
              COHERENCE_DECAY         = 0.03
              RECALL_DECAY            = 0.02
              RECALL_BOOST            = 0.1

              CHUNK_SIZE_LABELS = {
                (7..)   => :large,
                (5...7) => :medium,
                (3...5) => :small,
                (..3)   => :micro
              }.freeze

              COHERENCE_LABELS = {
                (0.8..)     => :tightly_chunked,
                (0.6...0.8) => :well_chunked,
                (0.4...0.6) => :loosely_chunked,
                (0.2...0.4) => :weakly_chunked,
                (..0.2)     => :unchunked
              }.freeze

              RECALL_LABELS = {
                (0.8..)     => :instant,
                (0.6...0.8) => :easy,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :difficult,
                (..0.2)     => :forgotten
              }.freeze

              CAPACITY_LABELS = {
                (0.8..)     => :overloaded,
                (0.6...0.8) => :near_capacity,
                (0.4...0.6) => :comfortable,
                (0.2...0.4) => :spacious,
                (..0.2)     => :empty
              }.freeze
            end
          end
        end
      end
    end
  end
end
