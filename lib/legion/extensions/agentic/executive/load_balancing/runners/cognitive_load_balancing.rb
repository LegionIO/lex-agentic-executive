# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module LoadBalancing
          module Runners
            module CognitiveLoadBalancing
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def register_cognitive_subsystem(name:, subsystem_type: :general,
                                               capacity: nil, **)
                cap = capacity || Helpers::Constants::DEFAULT_CAPACITY
                sub = engine.register_subsystem(name: name, subsystem_type: subsystem_type,
                                                capacity: cap)
                { success: true }.merge(sub.to_h)
              end

              def assign_cognitive_load(subsystem_id:, amount:, **)
                result = engine.assign_load(subsystem_id: subsystem_id, amount: amount)
                return { success: false, error: 'subsystem not found' } unless result

                { success: true }.merge(result.to_h)
              end

              def shed_cognitive_load(subsystem_id:, amount:, **)
                result = engine.shed_load(subsystem_id: subsystem_id, amount: amount)
                return { success: false, error: 'subsystem not found' } unless result

                { success: true, shed: result }
              end

              def auto_assign_load(amount:, subsystem_type: nil, **)
                result = engine.auto_assign(amount: amount, subsystem_type: subsystem_type)
                return { success: false, error: 'no available subsystem' } unless result

                { success: true, assigned_to: result.name }.merge(result.to_h)
              end

              def rebalance_cognitive_load(**)
                transfers = engine.rebalance
                { success: true, transfers: transfers, stats: engine.to_h }
              end

              def overloaded_subsystems_report(**)
                subs = engine.overloaded_subsystems
                { success: true, count: subs.size, subsystems: subs.map(&:to_h) }
              end

              def most_loaded_report(limit: 5, **)
                subs = engine.most_loaded(limit: limit)
                { success: true, limit: limit, subsystems: subs.map(&:to_h) }
              end

              def cognitive_load_balance_report(**)
                engine.balance_report
              end

              def cognitive_load_balancing_stats(**)
                engine.to_h
              end
            end
          end
        end
      end
    end
  end
end
