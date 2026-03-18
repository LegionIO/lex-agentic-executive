# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module FlexibilityTraining
          module Runners
            module CognitiveFlexibilityTraining
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def register_task(name:, domain:, difficulty: 0.5, engine: nil, **)
                eng    = engine || flexibility_engine
                result = eng.register_task(name: name, domain: domain, difficulty: difficulty)

                if result.is_a?(Helpers::TrainingTask)
                  Legion::Logging.debug "[cft] registered task name=#{name} domain=#{domain} difficulty=#{difficulty}"
                  { success: true, task: result.to_h }
                else
                  Legion::Logging.warn "[cft] register_task failed: #{result[:error]}"
                  { success: false }.merge(result)
                end
              end

              def perform_switch(from_task_id:, to_task_id:, engine: nil, **)
                eng    = engine || flexibility_engine
                result = eng.perform_switch(from_task_id: from_task_id, to_task_id: to_task_id)

                if result.is_a?(Helpers::SwitchTrial)
                  Legion::Logging.debug "[cft] switch trial cost=#{result.switch_cost.round(2)} " \
                                        "accuracy=#{result.accuracy.round(2)} label=#{result.switch_cost_label}"
                  { success: true, trial: result.to_h }
                else
                  Legion::Logging.warn "[cft] perform_switch failed: #{result[:error]}"
                  { success: false }.merge(result)
                end
              end

              def start_training_session(engine: nil, **)
                eng = engine || flexibility_engine
                eng.start_session
                Legion::Logging.debug '[cft] training session started'
                { success: true, status: :session_started }
              end

              def end_training_session(engine: nil, **)
                eng     = engine || flexibility_engine
                session = eng.end_session

                if session
                  Legion::Logging.debug "[cft] training session ended trial_count=#{session.size}"
                  { success: true, status: :session_ended, trial_count: session.size }
                else
                  { success: false, reason: :no_active_session }
                end
              end

              def average_switch_cost(window: 50, engine: nil, **)
                eng  = engine || flexibility_engine
                cost = eng.average_switch_cost(window: window)
                Legion::Logging.debug "[cft] average_switch_cost=#{cost.round(2)} window=#{window}"
                { success: true, average_switch_cost: cost, label: Helpers::Constants.label_for(cost, Helpers::Constants::SWITCH_COST_LABELS) }
              end

              def switch_cost_between(from_task_id:, to_task_id:, engine: nil, **)
                eng  = engine || flexibility_engine
                cost = eng.switch_cost_between(from_id: from_task_id, to_id: to_task_id)
                { success: true, from_task_id: from_task_id, to_task_id: to_task_id,
                  average_switch_cost: cost, label: Helpers::Constants.label_for(cost, Helpers::Constants::SWITCH_COST_LABELS) }
              end

              def flexibility_score(engine: nil, **)
                eng   = engine || flexibility_engine
                score = eng.flexibility_score
                Legion::Logging.debug "[cft] flexibility_score=#{score.round(2)}"
                { success: true, flexibility_score: score,
                  label: Helpers::Constants.label_for(score, Helpers::Constants::FLEXIBILITY_LABELS) }
              end

              def improvement_rate(engine: nil, **)
                eng  = engine || flexibility_engine
                rate = eng.improvement_rate
                Legion::Logging.debug "[cft] improvement_rate=#{rate.round(2)}"
                { success: true, improvement_rate: rate }
              end

              def hardest_switches(limit: 5, engine: nil, **)
                eng     = engine || flexibility_engine
                results = eng.hardest_switches(limit: limit)
                { success: true, switches: results, count: results.size }
              end

              def easiest_switches(limit: 5, engine: nil, **)
                eng     = engine || flexibility_engine
                results = eng.easiest_switches(limit: limit)
                { success: true, switches: results, count: results.size }
              end

              def training_report(engine: nil, **)
                eng    = engine || flexibility_engine
                report = eng.training_report
                Legion::Logging.debug "[cft] training_report flexibility=#{report[:flexibility_score]&.round(2)}"
                { success: true, report: report }
              end

              def list_tasks(engine: nil, **)
                eng = engine || flexibility_engine
                { success: true, tasks: eng.tasks.values.map(&:to_h), count: eng.tasks.size }
              end

              def get_task(task_id:, engine: nil, **)
                eng  = engine || flexibility_engine
                task = eng.tasks[task_id]
                task ? { success: true, task: task.to_h } : { success: false, reason: :not_found }
              end

              def list_trials(engine: nil, **)
                eng = engine || flexibility_engine
                { success: true, trials: eng.trials.map(&:to_h), count: eng.trials.size }
              end

              private

              def flexibility_engine
                @flexibility_engine ||= Helpers::FlexibilityEngine.new
              end
            end
          end
        end
      end
    end
  end
end
