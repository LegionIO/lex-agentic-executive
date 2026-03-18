# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Control
          module Helpers
            class Goal
              include Constants

              attr_reader :id, :description, :domain, :priority, :state, :progress, :created_at

              def initialize(id:, description:, domain: :general, priority: 0.5)
                @id          = id
                @description = description
                @domain      = domain
                @priority    = priority.to_f.clamp(0.0, 1.0)
                @state       = :active
                @progress    = 0.0
                @created_at  = Time.now.utc
              end

              def advance(amount: 0.1)
                return nil unless @state == :active

                @progress = [@progress + amount, 1.0].min
                complete! if @progress >= 1.0
                @progress
              end

              def complete!
                @state = :completed
              end

              def suspend!
                @state = :suspended if @state == :active
              end

              def resume!
                @state = :active if @state == :suspended
              end

              def abandon!
                @state = :abandoned unless @state == :completed
              end

              def active?
                @state == :active
              end

              def completed?
                @state == :completed
              end

              def to_h
                {
                  id:          @id,
                  description: @description,
                  domain:      @domain,
                  priority:    @priority.round(4),
                  state:       @state,
                  progress:    @progress.round(4)
                }
              end
            end
          end
        end
      end
    end
  end
end
