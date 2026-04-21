# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            class GoalPersistence
              GOAL_TTL = 86_400
              INDEX_KEY_SUFFIX = ':index'
              BRIDGE_KEY_SUFFIX = ':bridge'

              def initialize(namespace: 'legion_goals')
                @namespace = namespace
              end

              def save_goal(goal_hash)
                return false unless cache_available?

                key = goal_key(goal_hash[:id])
                Legion::Cache.set_sync(key, serialize(goal_hash), ttl: GOAL_TTL)
                update_index(goal_hash[:id], :add)
                true
              rescue StandardError => e
                log.error "GoalPersistence#save_goal: #{e.message}"
                false
              end

              def load_goal(id)
                return nil unless cache_available?

                raw = Legion::Cache.get(goal_key(id))
                return nil unless raw

                deserialize(raw)
              rescue StandardError => e
                log.error "GoalPersistence#load_goal: #{e.message}"
                nil
              end

              def delete_goal(id)
                return false unless cache_available?

                Legion::Cache.delete_sync(goal_key(id))
                update_index(id, :remove)
                true
              rescue StandardError => e
                log.error "GoalPersistence#delete_goal: #{e.message}"
                false
              end

              def save_all(goals_hash)
                return false unless cache_available?

                goals_hash.each_value { |g| save_goal(g.is_a?(Hash) ? g : g.to_h) }
                true
              rescue StandardError => e
                log.error "GoalPersistence#save_all: #{e.message}"
                false
              end

              def load_all
                return {} unless cache_available?

                ids = load_index
                return {} if ids.empty?

                goals = ids.each_with_object({}) do |id, result|
                  goal = load_goal(id)
                  result[id] = goal if goal
                end
                log.info "[goal_persistence] rehydrated #{goals.size} goals from cache"
                goals
              rescue StandardError => e
                log.error "GoalPersistence#load_all: #{e.message}"
                {}
              end

              def save_bridge_state(bridge_hash)
                return false unless cache_available?

                Legion::Cache.set_sync(bridge_key, serialize(bridge_hash), ttl: GOAL_TTL)
                true
              rescue StandardError => e
                log.error "GoalPersistence#save_bridge_state: #{e.message}"
                false
              end

              def load_bridge_state
                return {} unless cache_available?

                raw = Legion::Cache.get(bridge_key)
                return {} unless raw

                deserialize(raw)
              rescue StandardError => e
                log.error "GoalPersistence#load_bridge_state: #{e.message}"
                {}
              end

              private

              def log
                Legion::Logging
              end

              def cache_available?
                defined?(Legion::Cache) && Legion::Cache.connected?
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
                Legion::Cache.set_sync(index_key, serialize(ids), ttl: GOAL_TTL)
              end

              def load_index
                raw = Legion::Cache.get(index_key)
                return [] unless raw

                deserialize(raw)
              rescue StandardError => e
                log.error "GoalPersistence#load_index: #{e.message}"
                []
              end

              def serialize(obj)
                Legion::JSON.dump(obj)
              end

              def deserialize(raw)
                return raw if raw.is_a?(Hash) || raw.is_a?(Array)

                Legion::JSON.load(raw)
              rescue StandardError => e
                log.error "GoalPersistence#deserialize: #{e.message}"
                nil
              end
            end
          end
        end
      end
    end
  end
end
