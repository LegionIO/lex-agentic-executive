# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Chunking
          module Runners
            module CognitiveChunking
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def add_item(content:, domain: :general, engine: nil, **)
                eng = engine || chunking_engine
                result = eng.add_item(content: content, domain: domain)
                Legion::Logging.debug "[cognitive_chunking] add_item: domain=#{domain} success=#{result[:success]}"
                result
              end

              def create_chunk(label:, item_ids:, engine: nil, **)
                eng = engine || chunking_engine
                result = eng.create_chunk(label: label, item_ids: item_ids)
                Legion::Logging.debug "[cognitive_chunking] create_chunk: label=#{label} items=#{item_ids.size} success=#{result[:success]}"
                result
              end

              def merge_chunks(chunk_ids:, label:, engine: nil, **)
                eng = engine || chunking_engine
                result = eng.merge_chunks(chunk_ids: chunk_ids, label: label)
                Legion::Logging.debug "[cognitive_chunking] merge_chunks: label=#{label} sources=#{chunk_ids.size} success=#{result[:success]}"
                result
              end

              def load_to_working_memory(chunk_id:, engine: nil, **)
                eng = engine || chunking_engine
                result = eng.load_to_working_memory(chunk_id: chunk_id)
                Legion::Logging.debug "[cognitive_chunking] load_wm: chunk_id=#{chunk_id} wm_size=#{result[:working_memory_size]} success=#{result[:success]}"
                result
              end

              def unload_from_working_memory(chunk_id:, engine: nil, **)
                eng = engine || chunking_engine
                result = eng.unload_from_working_memory(chunk_id: chunk_id)
                Legion::Logging.debug "[cognitive_chunking] unload_wm: chunk_id=#{chunk_id} success=#{result[:success]}"
                result
              end

              def working_memory_status(engine: nil, **)
                eng    = engine || chunking_engine
                load   = eng.working_memory_load
                label  = Helpers::Constants::CAPACITY_LABELS.find { |range, _| range.cover?(load) }&.last || :empty

                Legion::Logging.debug "[cognitive_chunking] wm_status: load=#{load.round(2)} label=#{label}"
                {
                  success:    true,
                  size:       eng.working_memory.size,
                  capacity:   Helpers::Constants::WORKING_MEMORY_CAPACITY,
                  load:       load,
                  label:      label,
                  overloaded: eng.working_memory_overloaded?
                }
              end

              def decay_all(engine: nil, **)
                eng    = engine || chunking_engine
                result = eng.decay_all!
                Legion::Logging.debug "[cognitive_chunking] decay_all: chunks_decayed=#{result[:chunks_decayed]}"
                result
              end

              def reinforce_chunk(chunk_id:, engine: nil, **)
                eng    = engine || chunking_engine
                result = eng.reinforce_chunk(chunk_id: chunk_id)
                Legion::Logging.debug "[cognitive_chunking] reinforce_chunk: chunk_id=#{chunk_id} success=#{result[:success]}"
                result
              end

              def chunking_report(engine: nil, **)
                eng    = engine || chunking_engine
                report = eng.chunking_report
                eff = report[:chunking_efficiency].round(2)
                Legion::Logging.debug "[cognitive_chunking] report: items=#{report[:total_items]} chunks=#{report[:total_chunks]} efficiency=#{eff}"
                { success: true, report: report }
              end

              def strongest_chunks(limit: 10, engine: nil, **)
                eng    = engine || chunking_engine
                chunks = eng.strongest_chunks(limit: limit)
                Legion::Logging.debug "[cognitive_chunking] strongest_chunks: count=#{chunks.size}"
                { success: true, chunks: chunks }
              end

              def unchunked_items(engine: nil, **)
                eng   = engine || chunking_engine
                items = eng.unchunked_items
                Legion::Logging.debug "[cognitive_chunking] unchunked_items: count=#{items.size}"
                { success: true, items: items }
              end

              private

              def chunking_engine
                @chunking_engine ||= Helpers::ChunkingEngine.new
              end
            end
          end
        end
      end
    end
  end
end
