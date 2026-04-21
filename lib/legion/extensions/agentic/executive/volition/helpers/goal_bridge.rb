# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          module Helpers
            class GoalBridge
              def initialize(goal_client:)
                @goal_client = goal_client
                @bridged_intentions = {}
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

                result
              end

              private

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
