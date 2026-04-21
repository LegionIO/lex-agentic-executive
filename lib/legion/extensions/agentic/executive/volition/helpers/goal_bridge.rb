# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          module Helpers
            class GoalBridge
              def initialize(goal_client:, persistence: nil)
                @goal_client = goal_client
                @persistence = persistence || default_persistence
                @bridged_intentions = @persistence&.load_bridge_state || {}
                @mutex = Mutex.new
              end

              def bridge_intentions(intentions)
                result = { bridged: 0, skipped: 0, duplicates: 0, goal_ids: [], errors: [] }
                return result if intentions.nil? || intentions.empty?

                intentions.each do |intention|
                  outcome = bridge_one(intention)
                  case outcome[:status]
                  when :bridged
                    result[:bridged] += 1
                    result[:goal_ids] << outcome[:goal_id]
                  when :skipped   then result[:skipped] += 1
                  when :duplicate then result[:duplicates] += 1
                  when :error     then result[:errors] << outcome[:error]
                  end
                end

                persist_bridge_state
                log.info "[goal_bridge] bridged #{result[:bridged]} intentions to goals"
                result
              end

              private

              def log
                Legion::Logging
              end

              def default_persistence
                GoalManagement::Helpers::GoalPersistence.new
              rescue StandardError => e
                log.error "GoalBridge: #{e.message}"
                nil
              end

              def persist_bridge_state
                @persistence&.save_bridge_state(@bridged_intentions)
              end

              def bridge_one(intention)
                return { status: :skipped } unless intention[:state] == :active

                intent_key = "#{intention[:drive]}:#{intention[:domain]}:#{intention[:goal]}"
                @mutex.synchronize do
                  return { status: :duplicate } if @bridged_intentions.key?(intent_key)

                  goal_result = @goal_client.add_goal(
                    content:   intention[:goal],
                    parent_id: nil,
                    domain:    intention[:domain],
                    priority:  intention[:salience],
                    deadline:  nil
                  )

                  if goal_result[:success]
                    @bridged_intentions[intent_key] = goal_result[:goal][:id]
                    { status: :bridged, goal_id: goal_result[:goal][:id] }
                  else
                    { status: :error, error: goal_result[:error] }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
