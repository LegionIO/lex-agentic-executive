# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module FlexibilityTraining
          module Helpers
            class FlexibilityEngine
              attr_reader :tasks, :trials, :sessions

              def initialize
                @tasks           = {}
                @trials          = []
                @sessions        = []
                @current_session = nil
              end

              def register_task(name:, domain:, difficulty: 0.5)
                return { error: :max_tasks_reached } if @tasks.size >= Constants::MAX_TASKS
                return { error: :invalid_domain } unless Constants::TASK_DOMAINS.include?(domain)

                task = TrainingTask.new(name: name, domain: domain, difficulty: difficulty)
                @tasks[task.id] = task
                task
              end

              def perform_switch(from_task_id:, to_task_id:)
                return { error: :max_trials_reached } if @trials.size >= Constants::MAX_TRIALS

                from_task = @tasks[from_task_id]
                to_task   = @tasks[to_task_id]

                return { error: :task_not_found, missing: :from } unless from_task
                return { error: :task_not_found, missing: :to }   unless to_task

                cost     = compute_switch_cost(from_task, to_task)
                accuracy = compute_accuracy(to_task, cost)

                trial = SwitchTrial.new(
                  from_task_id: from_task_id,
                  to_task_id:   to_task_id,
                  switch_cost:  cost,
                  accuracy:     accuracy
                )

                @trials << trial
                @current_session << trial if @current_session

                from_task.practice!
                to_task.practice!

                trial
              end

              def start_session
                @current_session = []
                self
              end

              def end_session
                return nil unless @current_session

                session = @current_session.dup
                @sessions << session
                @sessions.shift while @sessions.size > Constants::MAX_SESSIONS
                @current_session = nil
                session
              end

              def average_switch_cost(window: 50)
                recent = @trials.last(window)
                return 0.0 if recent.empty?

                (recent.sum(&:switch_cost) / recent.size).round(10)
              end

              def switch_cost_between(from_id:, to_id:)
                pair_trials = @trials.select { |t| t.from_task_id == from_id && t.to_task_id == to_id }
                return 0.0 if pair_trials.empty?

                (pair_trials.sum(&:switch_cost) / pair_trials.size).round(10)
              end

              def improvement_rate
                return 0.0 if @trials.size < 4

                half   = @trials.size / 2
                early  = @trials.first(half)
                recent = @trials.last(half)

                early_avg  = early.sum(&:switch_cost) / early.size.to_f
                recent_avg = recent.sum(&:switch_cost) / recent.size.to_f

                ((early_avg - recent_avg) / early_avg.clamp(0.001, 1.0)).round(10)
              end

              def flexibility_score
                (1.0 - average_switch_cost).round(10)
              end

              def hardest_switches(limit: 5)
                pair_averages.sort_by { |_, cost| -cost }.first(limit).map do |pair, cost|
                  { from_task_id: pair[0], to_task_id: pair[1], average_switch_cost: cost.round(10) }
                end
              end

              def easiest_switches(limit: 5)
                pair_averages.sort_by { |_, cost| cost }.first(limit).map do |pair, cost|
                  { from_task_id: pair[0], to_task_id: pair[1], average_switch_cost: cost.round(10) }
                end
              end

              def training_report
                {
                  task_count:             @tasks.size,
                  trial_count:            @trials.size,
                  session_count:          @sessions.size,
                  average_switch_cost:    average_switch_cost,
                  flexibility_score:      flexibility_score,
                  improvement_rate:       improvement_rate,
                  flexibility_label:      Constants.label_for(flexibility_score, Constants::FLEXIBILITY_LABELS),
                  progress_label:         Constants.label_for(1.0 - average_switch_cost, Constants::PROGRESS_LABELS),
                  costly_trial_ratio:     costly_ratio,
                  successful_trial_ratio: success_ratio
                }
              end

              def to_h
                {
                  tasks:    @tasks.transform_values(&:to_h),
                  trials:   @trials.map(&:to_h),
                  sessions: @sessions.map { |s| s.map(&:to_h) },
                  report:   training_report
                }
              end

              private

              def compute_switch_cost(from_task, to_task)
                domain_penalty    = from_task.domain == to_task.domain ? 0.0 : 0.2
                difficulty_gap    = (to_task.difficulty - from_task.difficulty).abs * 0.3
                practice_discount = [from_task.practice_count * 0.005, 0.15].min
                fatigue_penalty   = [@trials.size * Constants::FATIGUE_RATE * 0.01, 0.1].min

                raw = Constants::DEFAULT_SWITCH_COST + domain_penalty + difficulty_gap - practice_discount + fatigue_penalty
                raw.clamp(0.0, 1.0).round(10)
              end

              def compute_accuracy(to_task, switch_cost)
                base     = to_task.baseline_performance
                penalty  = switch_cost * 0.4
                (base - penalty).clamp(0.0, 1.0).round(10)
              end

              def pair_averages
                grouped = @trials.group_by { |t| [t.from_task_id, t.to_task_id] }
                grouped.transform_values { |ts| ts.sum(&:switch_cost) / ts.size.to_f }
              end

              def costly_ratio
                return 0.0 if @trials.empty?

                (@trials.count(&:costly?).to_f / @trials.size).round(10)
              end

              def success_ratio
                return 0.0 if @trials.empty?

                (@trials.count(&:successful?).to_f / @trials.size).round(10)
              end
            end
          end
        end
      end
    end
  end
end
