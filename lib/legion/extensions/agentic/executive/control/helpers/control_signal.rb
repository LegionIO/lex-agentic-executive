# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Control
          module Helpers
            class ControlSignal
              include Constants

              attr_reader :effort_level, :conflict_detected, :error_detected,
                          :novelty_detected

              def initialize
                @effort_level = DEFAULT_EFFORT
                @conflict_detected = false
                @error_detected = false
                @novelty_detected = false
              end

              def detect_conflict
                @conflict_detected = true
                @effort_level = [@effort_level + CONFLICT_BOOST, EFFORT_CEILING].min
              end

              def detect_error
                @error_detected = true
                @effort_level = [@effort_level + ERROR_BOOST, EFFORT_CEILING].min
              end

              def detect_novelty
                @novelty_detected = true
                @effort_level = [@effort_level + NOVELTY_BOOST, EFFORT_CEILING].min
              end

              def reset_detections
                @conflict_detected = false
                @error_detected = false
                @novelty_detected = false
              end

              def mode
                return :override if @effort_level >= OVERRIDE_THRESHOLD
                return :controlled if @effort_level >= CONTROLLED_THRESHOLD

                :automatic
              end

              def effort_label
                EFFORT_LABELS.each { |range, lbl| return lbl if range.cover?(@effort_level) }
                :automatic
              end

              def decay
                @effort_level = [@effort_level - EFFORT_DECAY, EFFORT_FLOOR].max
              end

              def recover(amount: EFFORT_RECOVERY)
                @effort_level = [@effort_level + amount, EFFORT_CEILING].min
              end

              def to_h
                {
                  effort_level:      @effort_level.round(4),
                  mode:              mode,
                  effort_label:      effort_label,
                  conflict_detected: @conflict_detected,
                  error_detected:    @error_detected,
                  novelty_detected:  @novelty_detected
                }
              end
            end
          end
        end
      end
    end
  end
end
