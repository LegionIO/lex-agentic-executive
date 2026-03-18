# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Chunking
          module Helpers
            class InformationItem
              attr_reader :id, :content, :domain, :chunk_id, :created_at

              def initialize(content:, domain: :general)
                @id         = ::SecureRandom.uuid
                @content    = content
                @domain     = domain
                @chunked    = false
                @chunk_id   = nil
                @created_at = Time.now.utc
              end

              def chunked?
                @chunked
              end

              def assign_to_chunk!(chunk_id:)
                @chunked  = true
                @chunk_id = chunk_id
              end

              def unchunk!
                @chunked  = false
                @chunk_id = nil
              end

              def to_h
                {
                  id:         @id,
                  content:    @content,
                  domain:     @domain,
                  chunked:    @chunked,
                  chunk_id:   @chunk_id,
                  created_at: @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
