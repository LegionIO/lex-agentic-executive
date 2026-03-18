# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Control
          module Helpers
            class Controller
              include Constants

              attr_reader :goals, :signal, :history

              def initialize
                @goals    = {}
                @counter  = 0
                @signal   = ControlSignal.new
                @history  = []
              end

              def set_goal(description:, domain: :general, priority: 0.5)
                return nil if @goals.size >= MAX_GOALS

                @counter += 1
                goal_id = :"goal_#{@counter}"
                goal = Goal.new(id: goal_id, description: description, domain: domain, priority: priority)
                @goals[goal_id] = goal
                goal
              end

              def advance_goal(goal_id:, amount: 0.1)
                goal = @goals[goal_id]
                return nil unless goal

                goal.advance(amount: amount)
              end

              def suspend_goal(goal_id:)
                goal = @goals[goal_id]
                return nil unless goal

                goal.suspend!
              end

              def resume_goal(goal_id:)
                goal = @goals[goal_id]
                return nil unless goal

                goal.resume!
              end

              def abandon_goal(goal_id:)
                goal = @goals[goal_id]
                return nil unless goal

                goal.abandon!
              end

              def evaluate_control_demand(conflict: false, error: false, novelty: false)
                @signal.reset_detections
                @signal.detect_conflict if conflict
                @signal.detect_error if error
                @signal.detect_novelty if novelty
                record_evaluation
                @signal.to_h
              end

              def current_mode
                @signal.mode
              end

              def should_override?
                @signal.mode == :override
              end

              def should_control?
                %i[controlled override].include?(@signal.mode)
              end

              def active_goals
                @goals.values.select(&:active?).sort_by { |g| -g.priority }.map(&:to_h)
              end

              def top_goal
                active = @goals.values.select(&:active?)
                return nil if active.empty?

                active.max_by(&:priority).to_h
              end

              def goal_conflict?
                active = @goals.values.select(&:active?)
                return false if active.size < 2

                priorities = active.map(&:priority)
                (priorities.max - priorities.min) < 0.2 && active.size > 1
              end

              def tick
                @signal.decay
                check_goal_conflicts
                @signal.to_h
              end

              def to_h
                {
                  goal_count:    @goals.size,
                  active_goals:  @goals.values.count(&:active?),
                  effort_level:  @signal.effort_level.round(4),
                  mode:          current_mode,
                  effort_label:  @signal.effort_label,
                  goal_conflict: goal_conflict?,
                  history_size:  @history.size
                }
              end

              private

              def check_goal_conflicts
                @signal.detect_conflict if goal_conflict?
              end

              def record_evaluation
                @history << {
                  mode:     @signal.mode,
                  effort:   @signal.effort_level.round(4),
                  conflict: @signal.conflict_detected,
                  error:    @signal.error_detected,
                  novelty:  @signal.novelty_detected,
                  at:       Time.now.utc
                }
                @history.shift while @history.size > MAX_HISTORY
              end
            end
          end
        end
      end
    end
  end
end
