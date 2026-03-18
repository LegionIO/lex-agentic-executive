# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module ProspectiveMemory
          module Runners
            module ProspectiveMemory
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def create_intention(description:, trigger_type:, trigger_condition:,
                                   urgency: Helpers::Constants::DEFAULT_URGENCY,
                                   domain: nil, expires_at: nil, **)
                unless Helpers::Constants::TRIGGER_TYPES.include?(trigger_type)
                  return { error: :invalid_trigger_type, valid_types: Helpers::Constants::TRIGGER_TYPES }
                end

                intention = prospective_engine.create_intention(
                  description:       description,
                  trigger_type:      trigger_type,
                  trigger_condition: trigger_condition,
                  urgency:           urgency,
                  domain:            domain,
                  expires_at:        expires_at
                )

                Legion::Logging.debug "[prospective_memory] created intention id=#{intention.id[0..7]} " \
                                      "type=#{trigger_type} urgency=#{intention.urgency.round(2)}"

                { created: true, intention: intention.to_h }
              end

              def monitor_intention(intention_id:, **)
                intention = prospective_engine.monitor_intention(intention_id: intention_id)
                if intention
                  Legion::Logging.debug "[prospective_memory] monitoring intention id=#{intention_id[0..7]}"
                  { updated: true, intention: intention.to_h }
                else
                  { updated: false, reason: :not_found }
                end
              end

              def trigger_intention(intention_id:, **)
                intention = prospective_engine.trigger_intention(intention_id: intention_id)
                if intention
                  Legion::Logging.info "[prospective_memory] triggered intention id=#{intention_id[0..7]}"
                  { updated: true, intention: intention.to_h }
                else
                  { updated: false, reason: :not_found }
                end
              end

              def execute_intention(intention_id:, **)
                intention = prospective_engine.execute_intention(intention_id: intention_id)
                if intention
                  Legion::Logging.info "[prospective_memory] executed intention id=#{intention_id[0..7]}"
                  { updated: true, intention: intention.to_h }
                else
                  { updated: false, reason: :not_found }
                end
              end

              def cancel_intention(intention_id:, **)
                intention = prospective_engine.cancel_intention(intention_id: intention_id)
                if intention
                  Legion::Logging.debug "[prospective_memory] cancelled intention id=#{intention_id[0..7]}"
                  { updated: true, intention: intention.to_h }
                else
                  { updated: false, reason: :not_found }
                end
              end

              def check_expirations(**)
                expired_count = prospective_engine.check_expirations
                Legion::Logging.debug "[prospective_memory] expiration check expired=#{expired_count}"
                { expired_count: expired_count }
              end

              def pending_intentions(**)
                intentions = prospective_engine.pending_intentions
                Legion::Logging.debug "[prospective_memory] pending count=#{intentions.size}"
                { intentions: intentions.map(&:to_h), count: intentions.size }
              end

              def monitoring_intentions(**)
                intentions = prospective_engine.monitoring_intentions
                Legion::Logging.debug "[prospective_memory] monitoring count=#{intentions.size}"
                { intentions: intentions.map(&:to_h), count: intentions.size }
              end

              def triggered_intentions(**)
                intentions = prospective_engine.triggered_intentions
                Legion::Logging.debug "[prospective_memory] triggered count=#{intentions.size}"
                { intentions: intentions.map(&:to_h), count: intentions.size }
              end

              def intentions_by_domain(domain:, **)
                intentions = prospective_engine.by_domain(domain: domain)
                Legion::Logging.debug "[prospective_memory] by_domain domain=#{domain} count=#{intentions.size}"
                { intentions: intentions.map(&:to_h), count: intentions.size, domain: domain }
              end

              def intentions_by_urgency(min_urgency: 0.5, **)
                intentions = prospective_engine.by_urgency(min_urgency: min_urgency)
                Legion::Logging.debug "[prospective_memory] by_urgency min=#{min_urgency} count=#{intentions.size}"
                { intentions: intentions.map(&:to_h), count: intentions.size }
              end

              def most_urgent_intentions(limit: 5, **)
                intentions = prospective_engine.most_urgent(limit: limit)
                Legion::Logging.debug "[prospective_memory] most_urgent limit=#{limit} found=#{intentions.size}"
                { intentions: intentions.map(&:to_h), count: intentions.size }
              end

              def decay_urgency(**)
                prospective_engine.decay_all_urgency
                Legion::Logging.debug '[prospective_memory] urgency decay cycle complete'
                { decayed: true }
              end

              def execution_rate(**)
                rate = prospective_engine.execution_rate
                Legion::Logging.debug "[prospective_memory] execution_rate=#{rate.round(4)}"
                { execution_rate: rate }
              end

              def intention_report(**)
                report = prospective_engine.intention_report
                Legion::Logging.debug "[prospective_memory] report total=#{report[:total]}"
                report
              end

              private

              def prospective_engine
                @prospective_engine ||= Helpers::ProspectiveEngine.new
              end
            end
          end
        end
      end
    end
  end
end
