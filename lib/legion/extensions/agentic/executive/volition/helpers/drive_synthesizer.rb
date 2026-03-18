# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          module Helpers
            module DriveSynthesizer
              module_function

              def synthesize(tick_results: {}, cognitive_state: {})
                drives = {}
                drives[:curiosity] = compute_curiosity_drive(tick_results, cognitive_state)
                drives[:corrective] = compute_corrective_drive(cognitive_state)
                drives[:urgency] = compute_urgency_drive(tick_results, cognitive_state)
                drives[:epistemic] = compute_epistemic_drive(tick_results, cognitive_state)
                drives[:social] = compute_social_drive(cognitive_state)
                drives
              end

              def weighted_drives(drives)
                drives.each_with_object({}) do |(drive, strength), result|
                  weight = Constants::DRIVE_WEIGHTS[drive] || 0.0
                  result[drive] = {
                    raw:      strength,
                    weighted: (strength * weight).round(4),
                    weight:   weight
                  }
                end
              end

              def dominant_drive(drives)
                return nil if drives.empty?

                drives.max_by { |_, strength| strength }&.first
              end

              def generate_intentions(drives, cognitive_state: {})
                intentions = []

                drives.each do |drive, strength|
                  next if strength < Constants::DRIVE_THRESHOLD

                  intention = build_intention_for_drive(drive, strength, cognitive_state)
                  intentions << intention if intention
                end

                intentions.sort_by { |i| -(i[:salience] || 0) }
              end

              def compute_curiosity_drive(tick_results, cognitive_state)
                curiosity = cognitive_state[:curiosity] || {}
                wonder_data = tick_results[:working_memory_integration] || {}

                intensity = curiosity[:intensity] || wonder_data[:curiosity_intensity] || 0.0
                active_count = curiosity[:active_count] || wonder_data[:active_wonders] || 0

                count_factor = [active_count / 5.0, 1.0].min
                ((intensity * 0.7) + (count_factor * 0.3)).clamp(0.0, 1.0)
              end

              def compute_corrective_drive(cognitive_state)
                reflection = cognitive_state[:reflection] || {}
                health = reflection[:health] || 1.0
                pending = reflection[:pending_adaptations] || 0

                health_gap = 1.0 - health
                pending_factor = [pending / 3.0, 1.0].min
                ((health_gap * 0.6) + (pending_factor * 0.4)).clamp(0.0, 1.0)
              end

              def compute_urgency_drive(tick_results, cognitive_state)
                gut = tick_results[:gut_instinct] || cognitive_state[:gut] || {}
                emotion = tick_results[:emotional_evaluation] || {}

                arousal = emotion[:arousal] || cognitive_state.dig(:emotion, :arousal) || 0.5
                gut_signal = extract_gut_strength(gut)

                ((arousal * 0.5) + (gut_signal * 0.5)).clamp(0.0, 1.0)
              end

              def compute_epistemic_drive(tick_results, cognitive_state)
                pred = tick_results[:prediction_engine] || {}
                pred_state = cognitive_state[:prediction] || {}

                confidence = pred[:confidence] || pred_state[:confidence] || 0.5
                pending = pred_state[:pending_count] || 0

                confidence_gap = 1.0 - confidence
                pending_factor = [pending / 10.0, 1.0].min
                ((confidence_gap * 0.6) + (pending_factor * 0.4)).clamp(0.0, 1.0)
              end

              def compute_social_drive(cognitive_state)
                mesh = cognitive_state[:mesh] || {}
                trust = cognitive_state[:trust] || {}

                peer_count = mesh[:peer_count] || 0
                trust_level = trust[:avg_composite] || 0.5

                peer_factor = [peer_count / 5.0, 1.0].min
                ((peer_factor * 0.4) + (trust_level * 0.6)).clamp(0.0, 1.0)
              end

              def extract_gut_strength(gut)
                signal = gut[:signal]
                return 0.3 unless signal

                case signal
                when :alarm then 1.0
                when :heightened then 0.7
                when :explore   then 0.5
                when :attend    then 0.4
                when :calm      then 0.1
                else 0.3
                end
              end

              def build_intention_for_drive(drive, strength, cognitive_state)
                case drive
                when :curiosity  then build_curiosity_intention(strength, cognitive_state)
                when :corrective then build_corrective_intention(strength, cognitive_state)
                when :urgency    then build_urgency_intention(strength, cognitive_state)
                when :epistemic  then build_epistemic_intention(strength, cognitive_state)
                when :social     then build_social_intention(strength, cognitive_state)
                end
              end

              def build_curiosity_intention(strength, cognitive_state)
                question = cognitive_state.dig(:curiosity, :top_question) || 'explore knowledge gaps'
                domain = cognitive_state.dig(:curiosity, :top_domain) || :general
                Intention.new_intention(drive: :curiosity, domain: domain, goal: question, salience: strength)
              end

              def build_corrective_intention(strength, cognitive_state)
                severity = cognitive_state.dig(:reflection, :recent_severity) || 'cognitive health'
                Intention.new_intention(drive: :corrective, domain: :self, goal: "address #{severity}", salience: strength)
              end

              def build_urgency_intention(strength, _cognitive_state)
                Intention.new_intention(drive: :urgency, domain: :general, goal: 'respond to urgent signal', salience: strength)
              end

              def build_epistemic_intention(strength, _cognitive_state)
                Intention.new_intention(drive: :epistemic, domain: :general, goal: 'reduce prediction uncertainty', salience: strength)
              end

              def build_social_intention(strength, _cognitive_state)
                Intention.new_intention(drive: :social, domain: :general, goal: 'engage with peer agents', salience: strength)
              end
            end
          end
        end
      end
    end
  end
end
