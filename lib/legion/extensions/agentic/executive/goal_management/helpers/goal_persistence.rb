# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            class GoalPersistence
              include Legion::Cache::Helper if defined?(Legion::Cache::Helper)
              include Legion::JSON::Helper if defined?(Legion::JSON::Helper)

              GOAL_TTL = 86_400
              INDEX_KEY_SUFFIX = ':index'
              BRIDGE_KEY_SUFFIX = ':bridge'

              def initialize(namespace: 'legion_goals')
                @namespace = namespace
              end

              def save_goal(goal_hash)
                return false unless persistence_available?

                cache_set(goal_key(goal_hash[:id]), json_dump(goal_hash), ttl: GOAL_TTL)
                update_index(goal_hash[:id], :add)
                true
              rescue StandardError => e
                log.error "[goal_persistence] save_goal failed: #{e.message}"
                false
              end

              def load_goal(id)
                return nil unless persistence_available?

                raw = cache_get(goal_key(id))
                return nil unless raw

                json_load(raw)
              rescue StandardError => e
                log.error "[goal_persistence] load_goal failed: #{e.message}"
                nil
              end

              def delete_goal(id)
                return false unless persistence_available?

                cache_delete(goal_key(id))
                update_index(id, :remove)
                true
              rescue StandardError => e
                log.error "[goal_persistence] delete_goal failed: #{e.message}"
                false
              end

              def save_all(goals_hash)
                return false unless persistence_available?

                goals_hash.each_value { |g| save_goal(g.is_a?(Hash) ? g : g.to_h) }
                true
              rescue StandardError => e
                log.error "[goal_persistence] save_all failed: #{e.message}"
                false
              end

              def load_all
                return {} unless persistence_available?

                ids = load_index
                return {} if ids.empty?

                goals = ids.each_with_object({}) do |id, result|
                  goal = load_goal(id)
                  result[id] = goal if goal
                end
                log.info "[goal_persistence] rehydrated #{goals.size} goals from cache"
                goals
              rescue StandardError => e
                log.error "[goal_persistence] load_all failed: #{e.message}"
                {}
              end

              def save_bridge_state(bridge_hash)
                return false unless persistence_available?

                cache_set(bridge_key, json_dump(bridge_hash), ttl: GOAL_TTL)
                true
              rescue StandardError => e
                log.error "[goal_persistence] save_bridge_state failed: #{e.message}"
                false
              end

              def load_bridge_state
                return {} unless persistence_available?

                raw = cache_get(bridge_key)
                return {} unless raw

                json_load(raw)
              rescue StandardError => e
                log.error "[goal_persistence] load_bridge_state failed: #{e.message}"
                {}
              end

              private

              def log
                Legion::Logging
              end

              def persistence_available?
                respond_to?(:cache_connected?) && cache_connected?
              rescue StandardError => e
                log.debug "[goal_persistence] cache not available: #{e.message}"
                false
              end

              def goal_key(id) = "#{@namespace}:goal:#{id}"
              def index_key = "#{@namespace}#{INDEX_KEY_SUFFIX}"
              def bridge_key = "#{@namespace}#{BRIDGE_KEY_SUFFIX}"

              def update_index(id, operation)
                ids = load_index
                case operation
                when :add    then ids << id unless ids.include?(id)
                when :remove then ids.delete(id)
                end
                cache_set(index_key, json_dump(ids), ttl: GOAL_TTL)
              end

              def load_index
                raw = cache_get(index_key)
                return [] unless raw

                json_load(raw)
              rescue StandardError => e
                log.error "[goal_persistence] load_index failed: #{e.message}"
                []
              end
            end
          end
        end
      end
    end
  end
end
