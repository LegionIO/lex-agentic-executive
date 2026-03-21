# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          module Runners
            module Volition
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def form_intentions(tick_results: {}, cognitive_state: {}, **)
                drives = Helpers::DriveSynthesizer.synthesize(
                  tick_results:    tick_results,
                  cognitive_state: cognitive_state
                )

                new_intentions = Helpers::DriveSynthesizer.generate_intentions(drives, cognitive_state: cognitive_state)
                pushed = 0
                new_intentions.each do |intention|
                  result = intention_stack.push(intention)
                  pushed += 1 if result == :pushed
                end

                expired = intention_stack.decay_all
                dominant = Helpers::DriveSynthesizer.dominant_drive(drives)
                current = intention_stack.top

                Legion::Logging.debug "[volition] drives=#{format_drives(drives)} pushed=#{pushed} expired=#{expired} " \
                                      "active=#{intention_stack.active_count} top=#{current&.dig(:goal)}"

                {
                  drives:            drives,
                  dominant_drive:    dominant,
                  new_intentions:    pushed,
                  expired:           expired,
                  active_intentions: intention_stack.active_count,
                  current_intention: format_intention(current)
                }
              end

              def current_intention(**)
                intention = intention_stack.top
                return { intention: nil, has_will: false } unless intention

                {
                  intention: format_intention(intention),
                  has_will:  true,
                  drive:     intention[:drive],
                  goal:      intention[:goal],
                  salience:  intention[:salience]
                }
              end

              def complete_intention(intention_id:, **)
                result = intention_stack.complete(intention_id)
                Legion::Logging.info "[volition] complete intention=#{intention_id} result=#{result}"
                { status: result, intention_id: intention_id }
              end

              def suspend_intention(intention_id:, **)
                result = intention_stack.suspend(intention_id)
                Legion::Logging.info "[volition] suspend intention=#{intention_id} result=#{result}"
                { status: result, intention_id: intention_id }
              end

              def resume_intention(intention_id:, **)
                result = intention_stack.resume(intention_id)
                Legion::Logging.info "[volition] resume intention=#{intention_id} result=#{result}"
                { status: result, intention_id: intention_id }
              end

              def reinforce_intention(intention_id:, amount: 0.1, **)
                result = intention_stack.reinforce(intention_id, amount: amount)
                { status: result, intention_id: intention_id }
              end

              def form_absorption_intention(domains_at_risk:, neighboring_agents: [], severity: :warning, **)
                domains = Array(domains_at_risk)
                neighbors = Array(neighboring_agents)

                return { success: false, reason: :no_domains } if domains.empty?

                base_salience = severity.to_sym == :critical ? 0.85 : 0.55
                salience = [base_salience + (domains.size * 0.05), 1.0].min

                intention = Helpers::Intention.new_intention(
                  drive:    :epistemic,
                  domain:   :knowledge,
                  goal:     "absorb knowledge for domains: #{domains.join(', ')}",
                  salience: salience,
                  context:  { domains_at_risk: domains, target_agents: neighbors, severity: severity,
                             triggered_by: :knowledge_vulnerability }
                )

                result = intention_stack.push(intention)
                Legion::Logging.info "[volition] absorption intention formed: domains=#{domains.join(',')} " \
                                     "neighbors=#{neighbors.size} salience=#{salience.round(2)} result=#{result}"

                {
                  success:      %i[pushed duplicate].include?(result),
                  result:       result,
                  intention_id: intention[:intention_id],
                  salience:     salience,
                  domains:      domains,
                  targets:      neighbors
                }
              end

              def volition_status(**)
                stats = intention_stack.stats
                drives = Helpers::DriveSynthesizer.synthesize(tick_results: {}, cognitive_state: {})

                {
                  intention_stats: stats,
                  current_drives:  drives,
                  has_will:        stats[:active].positive?,
                  dominant_drive:  Helpers::DriveSynthesizer.dominant_drive(drives)
                }
              end

              def intention_history(limit: 20, **)
                all = intention_stack.intentions.last(limit)
                {
                  intentions: all.map { |i| format_intention(i) },
                  count:      all.size
                }
              end

              private

              def intention_stack
                @intention_stack ||= Helpers::IntentionStack.new
              end

              def format_intention(intention)
                return nil unless intention

                {
                  intention_id: intention[:intention_id],
                  drive:        intention[:drive],
                  drive_label:  Helpers::Intention.drive_label(intention[:drive]),
                  domain:       intention[:domain],
                  goal:         intention[:goal],
                  salience:     intention[:salience].round(3),
                  state:        intention[:state],
                  age_ticks:    intention[:age_ticks]
                }
              end

              def format_drives(drives)
                drives.map { |k, v| "#{k}=#{v.round(2)}" }.join(' ')
              end
            end
          end
        end
      end
    end
  end
end
