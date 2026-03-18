# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Autopilot
          module Helpers
            class AutopilotEngine
              include Constants

              attr_reader :current_mode, :energy

              def initialize
                @routines     = {}
                @events       = {}
                @current_mode = :deliberate
                @energy       = DEFAULT_ENERGY
              end

              def register_routine(pattern:, domain: :routine, familiarity: 0.0)
                prune_routines
                routine = Routine.new(pattern: pattern, domain: domain, familiarity: familiarity)
                @routines[routine.id] = routine
                routine
              end

              def execute_routine(routine_id:, success: true)
                routine = @routines[routine_id]
                return nil unless routine

                routine.execute!(success: success)
                cost = routine.autopilot_ready? ? AUTOPILOT_COST : DELIBERATE_COST
                drain_energy!(cost)
                auto_switch_mode(routine)
                routine
              end

              def switch_to_deliberate!(trigger: 'manual')
                return nil if @current_mode == :deliberate

                drain_energy!(OVERRIDE_COST)
                record_event(from: @current_mode, to: :deliberate, trigger: trigger, cost: OVERRIDE_COST)
                @current_mode = :deliberate
                @current_mode
              end

              def switch_to_autopilot!(trigger: 'manual')
                return nil if @current_mode == :autopilot

                record_event(from: @current_mode, to: :autopilot, trigger: trigger, cost: 0.0)
                @current_mode = :autopilot
                @current_mode
              end

              def rest!(amount: 0.1)
                @energy = (@energy + amount).clamp(0.0, 1.0).round(10)
                self
              end

              def decay_all!
                @routines.each_value(&:decay!)
                { routines_decayed: @routines.size }
              end

              def autopilot_routines = @routines.values.select(&:autopilot_ready?)
              def novel_routines = @routines.values.select(&:novel?)

              def autopilot_ratio
                return 0.0 if @routines.empty?

                (autopilot_routines.size.to_f / @routines.size).round(10)
              end

              def override_count = @events.values.count(&:override?)

              def most_familiar(limit: 5) = @routines.values.sort_by { |r| -r.familiarity }.first(limit)
              def least_familiar(limit: 5) = @routines.values.sort_by(&:familiarity).first(limit)

              def find_routine(routine_id:)
                @routines[routine_id]
              end

              def energy_label = Constants.label_for(ENERGY_LABELS, @energy)
              def mode_label = Constants.label_for(MODE_LABELS, autopilot_ratio)

              def exhausted?
                @energy <= 0.2
              end

              def autopilot_report
                {
                  current_mode:    @current_mode,
                  energy:          @energy,
                  energy_label:    energy_label,
                  exhausted:       exhausted?,
                  total_routines:  @routines.size,
                  autopilot_ready: autopilot_routines.size,
                  novel_count:     novel_routines.size,
                  autopilot_ratio: autopilot_ratio,
                  mode_label:      mode_label,
                  total_events:    @events.size,
                  override_count:  override_count,
                  most_familiar:   most_familiar(limit: 3).map(&:to_h)
                }
              end

              def to_h
                {
                  current_mode:    @current_mode,
                  energy:          @energy,
                  total_routines:  @routines.size,
                  autopilot_ratio: autopilot_ratio
                }
              end

              private

              def auto_switch_mode(routine)
                if routine.autopilot_ready? && @current_mode == :deliberate
                  record_event(from: :deliberate, to: :autopilot, trigger: "routine_familiar:#{routine.pattern}", cost: 0.0)
                  @current_mode = :autopilot
                elsif routine.novel? && @current_mode == :autopilot
                  drain_energy!(OVERRIDE_COST)
                  record_event(from: :autopilot, to: :deliberate, trigger: "routine_novel:#{routine.pattern}",
                               cost: OVERRIDE_COST)
                  @current_mode = :deliberate
                end
              end

              def record_event(from:, to:, trigger:, cost:)
                prune_events
                event = ModeEvent.new(from_mode: from, to_mode: to, trigger: trigger, energy_cost: cost)
                @events[event.id] = event
                event
              end

              def drain_energy!(amount)
                @energy = (@energy - amount).clamp(0.0, 1.0).round(10)
              end

              def prune_routines
                return if @routines.size < MAX_ROUTINES

                least = @routines.values.min_by(&:familiarity)
                @routines.delete(least.id) if least
              end

              def prune_events
                return if @events.size < MAX_EVENTS

                oldest = @events.values.min_by(&:created_at)
                @events.delete(oldest.id) if oldest
              end
            end
          end
        end
      end
    end
  end
end
