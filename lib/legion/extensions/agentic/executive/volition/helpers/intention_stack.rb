# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Volition
          module Helpers
            class IntentionStack
              attr_reader :intentions

              def initialize
                @intentions = []
              end

              def push(intention)
                return :duplicate if duplicate?(intention)
                return :capacity_full if @intentions.size >= Constants::MAX_INTENTIONS

                @intentions << intention
                sort!
                :pushed
              end

              def active
                @intentions.select { |i| Intention.active?(i) }
              end

              def top
                active.first
              end

              def by_drive(drive)
                @intentions.select { |i| i[:drive] == drive.to_sym && Intention.active?(i) }
              end

              def by_domain(domain)
                @intentions.select { |i| i[:domain] == domain.to_sym && Intention.active?(i) }
              end

              def find(intention_id)
                @intentions.find { |i| i[:intention_id] == intention_id }
              end

              def complete(intention_id)
                intention = find(intention_id)
                return :not_found unless intention

                intention[:state] = :completed
                intention[:completed_at] = Time.now.utc
                :completed
              end

              def suspend(intention_id)
                intention = find(intention_id)
                return :not_found unless intention

                intention[:state] = :suspended
                :suspended
              end

              def resume(intention_id)
                intention = find(intention_id)
                return :not_found unless intention
                return :not_suspended unless intention[:state] == :suspended

                intention[:state] = :active
                :resumed
              end

              def decay_all
                @intentions.each do |intention|
                  next unless Intention.active?(intention)

                  updated = Intention.decay(intention)
                  intention.merge!(updated)

                  intention[:state] = :expired if Intention.expired?(intention)
                end

                expired_count = @intentions.count { |i| i[:state] == :expired }
                prune_expired
                expired_count
              end

              def reinforce(intention_id, amount: 0.1)
                intention = find(intention_id)
                return :not_found unless intention

                updated = Intention.reinforce(intention, amount: amount)
                intention.merge!(updated)
                sort!
                :reinforced
              end

              def size
                @intentions.size
              end

              def active_count
                active.size
              end

              def stats
                by_state = @intentions.each_with_object(Hash.new(0)) { |i, h| h[i[:state]] += 1 }
                by_drive = active.each_with_object(Hash.new(0)) { |i, h| h[i[:drive]] += 1 }
                {
                  total:         @intentions.size,
                  active:        active_count,
                  by_state:      by_state,
                  by_drive:      by_drive,
                  top_intention: top&.slice(:intention_id, :drive, :domain, :goal, :salience)
                }
              end

              private

              def sort!
                @intentions.sort_by! { |i| -(i[:salience] || 0) }
              end

              def duplicate?(intention)
                @intentions.any? do |existing|
                  Intention.active?(existing) &&
                    existing[:drive] == intention[:drive] &&
                    existing[:domain] == intention[:domain] &&
                    existing[:goal] == intention[:goal]
                end
              end

              def prune_expired
                @intentions.reject! { |i| i[:state] == :expired }
              end
            end
          end
        end
      end
    end
  end
end
