# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            class GoalEngine
              include Constants

              attr_reader :goals, :root_goal_ids

              def initialize
                @goals         = {}
                @root_goal_ids = []
              end

              def add_goal(content:, parent_id: nil, domain: :general, priority: DEFAULT_PRIORITY, deadline: nil)
                return { success: false, error: 'goal limit reached' } if @goals.size >= MAX_GOALS

                if parent_id
                  parent = @goals[parent_id]
                  return { success: false, error: "parent goal #{parent_id} not found" } unless parent
                  return { success: false, error: 'max tree depth exceeded' } if depth_of(parent_id) >= MAX_DEPTH
                end

                prune_if_needed
                goal = Goal.new(content: content, parent_id: parent_id, domain: domain,
                                priority: priority, deadline: deadline)
                @goals[goal.id] = goal

                if parent_id
                  @goals[parent_id].add_sub_goal(goal.id)
                else
                  @root_goal_ids << goal.id
                end

                Legion::Logging.debug "[goal_management] add_goal id=#{goal.id} domain=#{domain} priority=#{priority.round(2)}"
                { success: true, goal: goal.to_h }
              end

              def decompose(goal_id:, sub_goals:)
                parent = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless parent

                created = sub_goals.map do |sg|
                  content  = sg.fetch(:content, sg.fetch('content', ''))
                  domain   = sg.fetch(:domain, sg.fetch('domain', parent.domain))
                  priority = sg.fetch(:priority, sg.fetch('priority', parent.priority))
                  deadline = sg.fetch(:deadline, sg.fetch('deadline', nil))

                  add_goal(content: content, parent_id: goal_id, domain: domain,
                           priority: priority, deadline: deadline)
                end

                failures = created.reject { |r| r[:success] }
                Legion::Logging.debug "[goal_management] decompose parent=#{goal_id} created=#{created.size - failures.size} failed=#{failures.size}"
                { success: true, parent_id: goal_id, created: created, failures: failures.size }
              end

              def activate_goal(goal_id:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                activated = goal.activate!
                Legion::Logging.debug "[goal_management] activate goal=#{goal_id} result=#{activated}"
                { success: activated, goal_id: goal_id, status: goal.status }
              end

              def complete_goal(goal_id:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                completed = goal.complete!
                Legion::Logging.debug "[goal_management] complete goal=#{goal_id} result=#{completed}"
                { success: completed, goal_id: goal_id, status: goal.status }
              end

              def abandon_goal(goal_id:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                abandoned = goal.abandon!
                Legion::Logging.debug "[goal_management] abandon goal=#{goal_id} result=#{abandoned}"
                { success: abandoned, goal_id: goal_id, status: goal.status }
              end

              def block_goal(goal_id:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                blocked = goal.block!
                Legion::Logging.debug "[goal_management] block goal=#{goal_id} result=#{blocked}"
                { success: blocked, goal_id: goal_id, status: goal.status }
              end

              def unblock_goal(goal_id:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                unblocked = goal.unblock!
                Legion::Logging.debug "[goal_management] unblock goal=#{goal_id} result=#{unblocked}"
                { success: unblocked, goal_id: goal_id, status: goal.status }
              end

              def advance_progress(goal_id:, amount:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                goal.advance_progress!(amount)
                propagate_progress_to_parent(goal_id)
                Legion::Logging.debug "[goal_management] advance_progress goal=#{goal_id} progress=#{goal.progress.round(2)}"
                { success: true, goal_id: goal_id, progress: goal.progress }
              end

              def detect_conflicts(goal_id:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                competing = @goals.values.select do |g|
                  g.id != goal_id &&
                    g.domain == goal.domain &&
                    %i[proposed active blocked].include?(g.status)
                end

                raw = competing.map do |g|
                  score = conflict_score(goal, g)
                  { goal_id: g.id, content: g.content, conflict_score: score, label: conflict_label(score) }
                end
                conflicts = raw.select { |c| c[:conflict_score] > 0.0 }
                               .sort_by { |c| -c[:conflict_score] }

                Legion::Logging.debug "[goal_management] detect_conflicts goal=#{goal_id} conflicts=#{conflicts.size}"
                { success: true, goal_id: goal_id, conflicts: conflicts, count: conflicts.size }
              end

              def active_goals
                @goals.values.select(&:active?)
              end

              def blocked_goals
                @goals.values.select(&:blocked?)
              end

              def overdue_goals
                @goals.values.select(&:overdue?)
              end

              def completed_goals
                @goals.values.select(&:completed?)
              end

              def goal_tree(goal_id:)
                goal = @goals[goal_id]
                return { success: false, error: "goal #{goal_id} not found" } unless goal

                { success: true, tree: build_tree(goal_id) }
              end

              def highest_priority(limit: 5)
                active = @goals.values.select { |g| %i[proposed active blocked].include?(g.status) }
                active.sort_by { |g| -g.priority }.first(limit)
              end

              def decay_all_priorities!
                inactive = @goals.values.reject { |g| g.status == :active }
                inactive.each(&:decay_priority!)
                Legion::Logging.debug "[goal_management] decay_all inactive=#{inactive.size}"
                { decayed: inactive.size }
              end

              def goal_report
                statuses = GOAL_STATUSES.to_h { |s| [s, 0] }
                @goals.each_value { |g| statuses[g.status] += 1 }
                {
                  total:         @goals.size,
                  root_goals:    @root_goal_ids.size,
                  statuses:      statuses,
                  overdue:       overdue_goals.size,
                  high_priority: @goals.values.count { |g| g.priority >= 0.6 }
                }
              end

              def to_h
                {
                  goals:         @goals.transform_values(&:to_h),
                  root_goal_ids: @root_goal_ids.dup,
                  report:        goal_report
                }
              end

              private

              def depth_of(goal_id, current_depth = 0)
                goal = @goals[goal_id]
                return current_depth unless goal&.parent_id

                depth_of(goal.parent_id, current_depth + 1)
              end

              def propagate_progress_to_parent(goal_id)
                goal = @goals[goal_id]
                return unless goal&.parent_id

                parent = @goals[goal.parent_id]
                return unless parent

                children = parent.sub_goal_ids.filter_map { |sid| @goals[sid] }
                return if children.empty?

                avg = children.sum(&:progress).round(10) / children.size
                parent.instance_variable_set(:@progress, avg.round(10))
                parent.instance_variable_set(:@updated_at, Time.now)
                propagate_progress_to_parent(goal.parent_id)
              end

              def conflict_score(goal_a, goal_b)
                priority_similarity = 1.0 - (goal_a.priority - goal_b.priority).abs
                combined_priority   = (goal_a.priority + goal_b.priority) / 2.0
                (priority_similarity * combined_priority).round(10)
              end

              def conflict_label(score)
                Constants::CONFLICT_LABELS.find { |l| l[:range].cover?(score) }&.fetch(:label, :none) || :none
              end

              def build_tree(goal_id)
                goal = @goals[goal_id]
                return nil unless goal

                node = goal.to_h
                node[:children] = goal.sub_goal_ids.filter_map { |sid| build_tree(sid) }
                node
              end

              def prune_if_needed
                return if @goals.size < MAX_GOALS

                candidates = @goals.values
                                   .select { |g| %i[completed abandoned].include?(g.status) }
                                   .sort_by(&:updated_at)

                to_remove = candidates.first([candidates.size, 10].min)
                to_remove.each { |g| remove_goal(g.id) }
              end

              def remove_goal(goal_id)
                goal = @goals.delete(goal_id)
                return unless goal

                @root_goal_ids.delete(goal_id)

                return unless goal.parent_id

                parent = @goals[goal.parent_id]
                parent&.sub_goal_ids&.delete(goal_id)
              end
            end
          end
        end
      end
    end
  end
end
