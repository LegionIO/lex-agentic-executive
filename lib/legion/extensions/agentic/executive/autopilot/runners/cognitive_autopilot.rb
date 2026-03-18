# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Autopilot
          module Runners
            module CognitiveAutopilot
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def register_routine(pattern:, domain: :routine, familiarity: 0.0, engine: nil, **)
                eng = engine || default_engine
                routine = eng.register_routine(pattern: pattern, domain: domain, familiarity: familiarity)
                { success: true, routine: routine.to_h }
              end

              def execute_routine(routine_id:, success: true, engine: nil, **)
                eng = engine || default_engine
                routine = eng.execute_routine(routine_id: routine_id, success: success)
                return { success: false, error: 'routine not found' } unless routine

                { success: true, routine: routine.to_h, mode: eng.current_mode, energy: eng.energy }
              end

              def switch_to_deliberate(trigger: 'manual', engine: nil, **)
                eng = engine || default_engine
                result = eng.switch_to_deliberate!(trigger: trigger)
                return { success: false, error: 'already in deliberate mode' } unless result

                { success: true, mode: :deliberate, energy: eng.energy }
              end

              def switch_to_autopilot(trigger: 'manual', engine: nil, **)
                eng = engine || default_engine
                result = eng.switch_to_autopilot!(trigger: trigger)
                return { success: false, error: 'already in autopilot mode' } unless result

                { success: true, mode: :autopilot, energy: eng.energy }
              end

              def rest(amount: 0.1, engine: nil, **)
                eng = engine || default_engine
                eng.rest!(amount: amount)
                { success: true, energy: eng.energy, energy_label: eng.energy_label }
              end

              def decay_all(engine: nil, **)
                eng = engine || default_engine
                result = eng.decay_all!
                { success: true, **result }
              end

              def autopilot_routines(engine: nil, **)
                eng = engine || default_engine
                { success: true, routines: eng.autopilot_routines.map(&:to_h), count: eng.autopilot_routines.size }
              end

              def novel_routines(engine: nil, **)
                eng = engine || default_engine
                { success: true, routines: eng.novel_routines.map(&:to_h), count: eng.novel_routines.size }
              end

              def most_familiar(limit: 5, engine: nil, **)
                eng = engine || default_engine
                { success: true, routines: eng.most_familiar(limit: limit).map(&:to_h) }
              end

              def get_routine(routine_id:, engine: nil, **)
                eng = engine || default_engine
                routine = eng.find_routine(routine_id: routine_id)
                return { success: false, error: 'routine not found' } unless routine

                { success: true, routine: routine.to_h }
              end

              def autopilot_status(engine: nil, **)
                eng = engine || default_engine
                { success: true, **eng.autopilot_report }
              end

              private

              def default_engine
                @default_engine ||= Helpers::AutopilotEngine.new
              end
            end
          end
        end
      end
    end
  end
end
