# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module ExecutiveFunction
          module Runners
            module ExecutiveFunction
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def inhibit(target:, reason: :prepotent_response, **)
                result = controller.inhibit(target: target, reason: reason)
                Legion::Logging.debug "[executive_function] inhibit target=#{target} success=#{result[:success]}"
                result
              end

              def shift_task(from:, to:, **)
                result = controller.shift_task(from: from, to: to)
                Legion::Logging.debug "[executive_function] shift from=#{from} to=#{to} " \
                                      "cost=#{result[:switch_cost]&.round(3)} success=#{result[:success]}"
                result
              end

              def update_wm(slot:, new_value:, old_value: nil, **)
                result = controller.update_wm(slot: slot, old_value: old_value, new_value: new_value)
                Legion::Logging.debug "[executive_function] update_wm slot=#{slot} success=#{result[:success]}"
                result
              end

              def common_ef_status(**)
                level = controller.common_ef_level
                Legion::Logging.debug "[executive_function] common_ef_level=#{level.round(3)}"
                { success: true, common_ef_level: level, components: controller.to_h[:components] }
              end

              def component_status(component:, **)
                comp = controller.component(component)
                return { success: false, reason: :unknown_component } unless comp

                Legion::Logging.debug "[executive_function] component_status #{component} " \
                                      "effective=#{comp.effective_capacity.round(3)}"
                { success: true, component: comp.to_h }
              end

              def can_perform(operation:, **)
                result = case operation.to_sym
                         when :inhibit  then { can_perform: controller.can_inhibit? }
                         when :shift    then { can_perform: controller.can_shift? }
                         when :update   then { can_perform: controller.can_update? }
                         else           { can_perform: false, reason: :unknown_operation }
                         end
                Legion::Logging.debug "[executive_function] can_perform #{operation} => #{result[:can_perform]}"
                result.merge(success: true, operation: operation)
              end

              def task_switch_cost(from:, to:, **)
                cost = from.to_s == to.to_s ? 0.0 : Helpers::ExecutiveController::SWITCH_COST
                cap  = controller.component(:shifting)&.effective_capacity || 0.0
                Legion::Logging.debug "[executive_function] task_switch_cost from=#{from} to=#{to} cost=#{cost}"
                { success: true, from: from, to: to, switch_cost: cost, shifting_capacity: cap }
              end

              def executive_load(**)
                stats = controller.to_h
                comps = stats[:components]
                load  = comps.values.sum { |c| c[:fatigue] } / comps.size.to_f
                Legion::Logging.debug "[executive_function] executive_load=#{load.round(3)}"
                { success: true, executive_load: load.round(4), common_ef_level: stats[:common_ef_level],
                  components: comps }
              end

              def update_executive_function(component:, capacity:, **)
                comp = controller.component(component)
                return { success: false, reason: :unknown_component } unless comp

                clamped = capacity.to_f.clamp(
                  Helpers::EfComponent::CAPACITY_FLOOR,
                  Helpers::EfComponent::CAPACITY_CEILING
                )
                comp.instance_variable_set(:@capacity, clamped)
                Legion::Logging.debug "[executive_function] update component=#{component} capacity=#{clamped}"
                { success: true, component: component, new_capacity: clamped }
              end

              def executive_function_stats(**)
                stats = controller.to_h
                Legion::Logging.debug "[executive_function] stats common_ef=#{stats[:common_ef_level]}"
                { success: true }.merge(stats)
              end

              private

              def controller
                @controller ||= Helpers::ExecutiveController.new
              end
            end
          end
        end
      end
    end
  end
end
