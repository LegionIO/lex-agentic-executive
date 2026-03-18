# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Chunking
          module Helpers
            class Chunk
              include Constants

              attr_reader :id, :label, :item_ids, :sub_chunk_ids, :coherence, :recall_strength,
                          :access_count, :created_at

              def initialize(label:, item_ids: [])
                @id             = ::SecureRandom.uuid
                @label          = label
                @item_ids       = item_ids.dup
                @sub_chunk_ids  = []
                @coherence      = DEFAULT_COHERENCE
                @recall_strength = 0.8
                @access_count   = 0
                @created_at     = Time.now.utc
              end

              def add_item!(item_id:)
                @item_ids << item_id unless @item_ids.include?(item_id)
              end

              def remove_item!(item_id:)
                @item_ids.delete(item_id)
              end

              def add_sub_chunk!(chunk_id:)
                @sub_chunk_ids << chunk_id unless @sub_chunk_ids.include?(chunk_id)
              end

              def reinforce!
                @access_count   += 1
                @coherence       = [(@coherence + COHERENCE_BOOST).round(10), 1.0].min
                @recall_strength = [(@recall_strength + RECALL_BOOST).round(10), 1.0].min
              end

              def decay!
                @recall_strength = [(@recall_strength - RECALL_DECAY).round(10), 0.0].max
                @coherence       = [(@coherence - COHERENCE_DECAY).round(10), 0.0].max
              end

              def size
                @item_ids.size
              end

              def hierarchical?
                !@sub_chunk_ids.empty?
              end

              def coherence_label
                COHERENCE_LABELS.find { |range, _| range.cover?(@coherence) }&.last || :unchunked
              end

              def recall_label
                RECALL_LABELS.find { |range, _| range.cover?(@recall_strength) }&.last || :forgotten
              end

              def size_label
                CHUNK_SIZE_LABELS.find { |range, _| range.cover?(size) }&.last || :micro
              end

              def to_h
                {
                  id:              @id,
                  label:           @label,
                  item_ids:        @item_ids.dup,
                  sub_chunk_ids:   @sub_chunk_ids.dup,
                  coherence:       @coherence.round(10),
                  recall_strength: @recall_strength.round(10),
                  access_count:    @access_count,
                  created_at:      @created_at,
                  size:            size,
                  hierarchical:    hierarchical?,
                  coherence_label: coherence_label,
                  recall_label:    recall_label,
                  size_label:      size_label
                }
              end
            end
          end
        end
      end
    end
  end
end
