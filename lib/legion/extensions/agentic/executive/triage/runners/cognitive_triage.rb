# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Triage
          module Runners
            module CognitiveTriage
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def add_demand(description:, domain: :general, severity: :moderate, urgency: :soon, engine: nil, **)
                eng = engine || default_engine
                demand = eng.add_demand(
                  description: description, domain: domain, severity: severity, urgency: urgency
                )
                { success: true, demand: demand.to_h, capacity: eng.capacity }
              end

              def process_demand(demand_id:, engine: nil, **)
                eng = engine || default_engine
                demand = eng.process_demand(demand_id: demand_id)
                return { success: false, error: 'demand not found or not active' } unless demand

                { success: true, demand: demand.to_h }
              end

              def complete_demand(demand_id:, engine: nil, **)
                eng = engine || default_engine
                demand = eng.complete_demand(demand_id: demand_id)
                return { success: false, error: 'demand not found' } unless demand

                { success: true, demand: demand.to_h, capacity: eng.capacity }
              end

              def defer_demand(demand_id:, engine: nil, **)
                eng = engine || default_engine
                demand = eng.defer_demand(demand_id: demand_id)
                return { success: false, error: 'demand not found or not active' } unless demand

                { success: true, demand: demand.to_h, capacity: eng.capacity }
              end

              def drop_demand(demand_id:, engine: nil, **)
                eng = engine || default_engine
                demand = eng.drop_demand(demand_id: demand_id)
                return { success: false, error: 'demand not found or not active' } unless demand

                { success: true, demand: demand.to_h, capacity: eng.capacity }
              end

              def next_demand(engine: nil, **)
                eng = engine || default_engine
                demand = eng.next_demand
                return { success: true, found: false } unless demand

                { success: true, found: true, demand: demand.to_h }
              end

              def active_demands(engine: nil, **)
                eng = engine || default_engine
                { success: true, demands: eng.active_demands.map(&:to_h), count: eng.active_demands.size }
              end

              def red_demands(engine: nil, **)
                eng = engine || default_engine
                { success: true, demands: eng.red_demands.map(&:to_h), count: eng.red_demands.size }
              end

              def demands_by_severity(severity:, engine: nil, **)
                eng = engine || default_engine
                demands = eng.demands_by_severity(severity: severity)
                { success: true, demands: demands.map(&:to_h), count: demands.size }
              end

              def demands_by_domain(domain:, engine: nil, **)
                eng = engine || default_engine
                demands = eng.demands_by_domain(domain: domain)
                { success: true, demands: demands.map(&:to_h), count: demands.size }
              end

              def capacity_status(engine: nil, **)
                eng = engine || default_engine
                {
                  success:        true,
                  capacity:       eng.capacity,
                  capacity_label: eng.capacity_label,
                  overloaded:     eng.overloaded?,
                  queue_pressure: eng.queue_pressure,
                  queue_label:    eng.queue_label
                }
              end

              def triage_report(engine: nil, **)
                eng = engine || default_engine
                { success: true, report: eng.triage_report }
              end

              private

              def default_engine
                @default_engine ||= Helpers::TriageEngine.new
              end
            end
          end
        end
      end
    end
  end
end
