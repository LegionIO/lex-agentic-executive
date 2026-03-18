# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            class Goal
              include Constants

              attr_reader :id, :content, :parent_id, :sub_goal_ids, :status,
                          :priority, :progress, :domain, :deadline,
                          :created_at, :updated_at

              def initialize(content:, parent_id: nil, domain: :general, priority: DEFAULT_PRIORITY, deadline: nil)
                @id           = SecureRandom.uuid
                @content      = content
                @parent_id    = parent_id
                @sub_goal_ids = []
                @status       = :proposed
                @priority     = priority.clamp(0.0, 1.0)
                @progress     = 0.0
                @domain       = domain
                @deadline     = deadline
                @created_at   = Time.now
                @updated_at   = Time.now
              end

              def activate!
                return false unless %i[proposed blocked].include?(@status)

                @status     = :active
                @updated_at = Time.now
                true
              end

              def complete!
                return false unless %i[active blocked].include?(@status)

                @status     = :completed
                @progress   = 1.0
                @updated_at = Time.now
                true
              end

              def abandon!
                return false if %i[completed abandoned].include?(@status)

                @status     = :abandoned
                @updated_at = Time.now
                true
              end

              def block!
                return false unless @status == :active

                @status     = :blocked
                @updated_at = Time.now
                true
              end

              def unblock!
                return false unless @status == :blocked

                @status     = :active
                @updated_at = Time.now
                true
              end

              def advance_progress!(amount)
                return false if %i[completed abandoned].include?(@status)

                @progress   = (@progress + amount).clamp(0.0, 1.0).round(10)
                @updated_at = Time.now
                true
              end

              def boost_priority!
                @priority   = (@priority + PRIORITY_BOOST).clamp(0.0, 1.0).round(10)
                @updated_at = Time.now
              end

              def decay_priority!
                @priority   = (@priority - PRIORITY_DECAY).clamp(0.0, 1.0).round(10)
                @updated_at = Time.now
              end

              def add_sub_goal(goal_id)
                @sub_goal_ids << goal_id unless @sub_goal_ids.include?(goal_id)
              end

              def root?
                @parent_id.nil?
              end

              def leaf?
                @sub_goal_ids.empty?
              end

              def blocked?
                @status == :blocked
              end

              def completed?
                @status == :completed
              end

              def active?
                @status == :active
              end

              def overdue?
                !@deadline.nil? && Time.now > @deadline
              end

              def priority_label
                PRIORITY_LABELS.find { |l| l[:range].cover?(@priority) }&.fetch(:label, :trivial) || :trivial
              end

              def progress_label
                PROGRESS_LABELS.find { |l| l[:range].cover?(@progress) }&.fetch(:label, :not_started) || :not_started
              end

              def to_h
                {
                  id:             @id,
                  content:        @content,
                  parent_id:      @parent_id,
                  sub_goal_ids:   @sub_goal_ids.dup,
                  status:         @status,
                  priority:       @priority,
                  priority_label: priority_label,
                  progress:       @progress,
                  progress_label: progress_label,
                  domain:         @domain,
                  deadline:       @deadline,
                  overdue:        overdue?,
                  root:           root?,
                  leaf:           leaf?,
                  created_at:     @created_at,
                  updated_at:     @updated_at
                }
              end
            end
          end
        end
      end
    end
  end
end
