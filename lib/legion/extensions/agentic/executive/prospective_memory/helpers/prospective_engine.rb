# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module ProspectiveMemory
          module Helpers
            class ProspectiveEngine
              attr_reader :intentions

              def initialize
                @intentions = {}
              end

              def create_intention(description:, trigger_type:, trigger_condition:,
                                   urgency: Constants::DEFAULT_URGENCY, domain: nil, expires_at: nil)
                evict_oldest! if @intentions.size >= Constants::MAX_INTENTIONS

                intention = Intention.new(
                  description:       description,
                  trigger_type:      trigger_type,
                  trigger_condition: trigger_condition,
                  urgency:           urgency,
                  domain:            domain,
                  expires_at:        expires_at
                )
                @intentions[intention.id] = intention
                intention
              end

              def monitor_intention(intention_id:)
                intention = fetch(intention_id)
                return nil unless intention

                intention.monitor!
                intention
              end

              def trigger_intention(intention_id:)
                intention = fetch(intention_id)
                return nil unless intention

                intention.trigger!
                intention
              end

              def execute_intention(intention_id:)
                intention = fetch(intention_id)
                return nil unless intention

                intention.execute!
                intention
              end

              def cancel_intention(intention_id:)
                intention = fetch(intention_id)
                return nil unless intention

                intention.cancel!
                intention
              end

              def check_expirations
                expired_count = 0
                @intentions.each_value do |intention|
                  next unless %i[pending monitoring].include?(intention.status) && intention.expired?

                  intention.expire!
                  expired_count += 1
                end
                expired_count
              end

              def pending_intentions
                by_status(:pending)
              end

              def monitoring_intentions
                by_status(:monitoring)
              end

              def triggered_intentions
                by_status(:triggered)
              end

              def by_domain(domain:)
                @intentions.values.select { |i| i.domain == domain }
              end

              def by_urgency(min_urgency: 0.5)
                @intentions.values.select { |i| i.urgency >= min_urgency }
              end

              def most_urgent(limit: 5)
                active = @intentions.values.reject { |i| %i[executed expired cancelled].include?(i.status) }
                active.sort_by { |i| -i.urgency }.first(limit)
              end

              def decay_all_urgency
                @intentions.each_value do |intention|
                  next unless %i[pending monitoring].include?(intention.status)

                  intention.decay_urgency!
                end
              end

              def execution_rate
                terminal = @intentions.values.select { |i| %i[executed expired cancelled].include?(i.status) }
                return 0.0 if terminal.empty?

                executed = terminal.count { |i| i.status == :executed }
                (executed.to_f / terminal.size).round(10)
              end

              def intention_report
                all    = @intentions.values
                counts = Constants::STATUS_TYPES.to_h do |s|
                  [s, all.count { |i| i.status == s }]
                end
                {
                  total:          all.size,
                  by_status:      counts,
                  execution_rate: execution_rate,
                  most_urgent:    most_urgent(limit: 5).map(&:to_h)
                }
              end

              def to_h
                {
                  intentions:      @intentions.transform_values(&:to_h),
                  intention_count: @intentions.size,
                  execution_rate:  execution_rate
                }
              end

              private

              def fetch(intention_id)
                @intentions[intention_id]
              end

              def by_status(status)
                @intentions.values.select { |i| i.status == status }
              end

              def evict_oldest!
                oldest_id = @intentions.min_by { |_id, i| i.created_at }&.first
                @intentions.delete(oldest_id) if oldest_id
              end
            end
          end
        end
      end
    end
  end
end
