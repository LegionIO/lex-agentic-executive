# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Chunking
          module Helpers
            class ChunkingEngine
              include Constants

              attr_reader :items, :chunks, :working_memory

              def initialize
                @items          = {}
                @chunks         = {}
                @working_memory = []
              end

              def add_item(content:, domain: :general)
                return { success: false, error: :capacity_exceeded } if @items.size >= MAX_ITEMS

                item = InformationItem.new(content: content, domain: domain)
                @items[item.id] = item
                { success: true, item_id: item.id, item: item.to_h }
              end

              def create_chunk(label:, item_ids:)
                return { success: false, error: :capacity_exceeded } if @chunks.size >= MAX_CHUNKS
                return { success: false, error: :empty_item_ids } if item_ids.empty?

                valid_ids = item_ids.select { |id| @items.key?(id) }
                return { success: false, error: :no_valid_items } if valid_ids.empty?

                chunk = Chunk.new(label: label, item_ids: valid_ids)
                @chunks[chunk.id] = chunk
                valid_ids.each { |id| @items[id]&.assign_to_chunk!(chunk_id: chunk.id) }

                { success: true, chunk_id: chunk.id, chunk: chunk.to_h }
              end

              def merge_chunks(chunk_ids:, label:)
                return { success: false, error: :capacity_exceeded } if @chunks.size >= MAX_CHUNKS
                return { success: false, error: :insufficient_chunks } if chunk_ids.size < 2

                valid_chunk_ids = chunk_ids.select { |id| @chunks.key?(id) }
                return { success: false, error: :no_valid_chunks } if valid_chunk_ids.size < 2

                merged_item_ids = valid_chunk_ids.flat_map { |id| @chunks[id].item_ids }.uniq
                parent = Chunk.new(label: label, item_ids: merged_item_ids)
                valid_chunk_ids.each { |id| parent.add_sub_chunk!(chunk_id: id) }
                @chunks[parent.id] = parent

                { success: true, chunk_id: parent.id, chunk: parent.to_h, merged_from: valid_chunk_ids }
              end

              def load_to_working_memory(chunk_id:)
                return { success: false, error: :chunk_not_found } unless @chunks.key?(chunk_id)
                return { success: false, error: :already_loaded } if @working_memory.include?(chunk_id)
                return { success: false, error: :capacity_exceeded } if @working_memory.size >= WORKING_MEMORY_CAPACITY

                @working_memory << chunk_id
                @chunks[chunk_id].reinforce!
                { success: true, chunk_id: chunk_id, working_memory_size: @working_memory.size }
              end

              def unload_from_working_memory(chunk_id:)
                return { success: false, error: :not_in_working_memory } unless @working_memory.include?(chunk_id)

                @working_memory.delete(chunk_id)
                { success: true, chunk_id: chunk_id, working_memory_size: @working_memory.size }
              end

              def working_memory_load
                return 0.0 if WORKING_MEMORY_CAPACITY.zero?

                (@working_memory.size.to_f / WORKING_MEMORY_CAPACITY).round(10)
              end

              def working_memory_overloaded?
                @working_memory.size > WORKING_MEMORY_CAPACITY
              end

              def decay_all!
                @chunks.each_value(&:decay!)
                { success: true, chunks_decayed: @chunks.size }
              end

              def reinforce_chunk(chunk_id:)
                return { success: false, error: :chunk_not_found } unless @chunks.key?(chunk_id)

                @chunks[chunk_id].reinforce!
                { success: true, chunk_id: chunk_id, chunk: @chunks[chunk_id].to_h }
              end

              def strongest_chunks(limit: 10)
                @chunks.values
                       .sort_by { |c| -c.recall_strength }
                       .first(limit)
                       .map(&:to_h)
              end

              def unchunked_items
                @items.values.reject(&:chunked?).map(&:to_h)
              end

              def chunking_efficiency
                return 0.0 if @items.empty?

                chunked_count = @items.values.count(&:chunked?)
                (chunked_count.to_f / @items.size).round(10)
              end

              def chunking_report
                wm_load = working_memory_load
                capacity_label = CAPACITY_LABELS.find { |range, _| range.cover?(wm_load) }&.last || :empty

                {
                  total_items:         @items.size,
                  total_chunks:        @chunks.size,
                  unchunked_items:     unchunked_items.size,
                  chunking_efficiency: chunking_efficiency,
                  working_memory:      {
                    current:   @working_memory.size,
                    capacity:  WORKING_MEMORY_CAPACITY,
                    load:      wm_load,
                    label:     capacity_label,
                    chunk_ids: @working_memory.dup
                  },
                  strongest_chunks:    strongest_chunks(limit: 5)
                }
              end

              def to_h
                {
                  items:          @items.transform_values(&:to_h),
                  chunks:         @chunks.transform_values(&:to_h),
                  working_memory: @working_memory.dup
                }
              end
            end
          end
        end
      end
    end
  end
end
