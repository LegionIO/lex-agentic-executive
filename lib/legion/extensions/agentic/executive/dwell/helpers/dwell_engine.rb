# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Dwell
          module Helpers
            class DwellEngine
              include Constants

              def initialize
                @topics = {}
                @current_topic_id = nil
              end

              def add_topic(content:, topic_type: :concept, salience: 0.5,
                            novelty: 0.5, emotional_intensity: 0.3, complexity: 0.5)
                prune_if_needed
                topic = DwellTopic.new(
                  content: content, topic_type: topic_type, salience: salience,
                  novelty: novelty, emotional_intensity: emotional_intensity, complexity: complexity
                )
                @topics[topic.id] = topic
                topic
              end

              def focus_on(topic_id:)
                topic = @topics[topic_id]
                return nil unless topic

                topic.engage!
                @current_topic_id = topic_id
                topic
              end

              def disengage(topic_id:, force: 0.0)
                topic = @topics[topic_id]
                return nil unless topic

                topic.disengage!(force: force)
                @current_topic_id = nil if @current_topic_id == topic_id
                topic
              end

              def decay_all!
                @topics.each_value(&:decay!)
                { topics_decayed: @topics.size }
              end

              def current_topic
                @topics[@current_topic_id]
              end

              def sticky_topics
                @topics.values.select(&:sticky?)
              end

              def fleeting_topics
                @topics.values.select(&:fleeting?)
              end

              def ruminating_topics
                @topics.values.select(&:ruminating?)
              end

              def most_engaging(limit: 5)
                @topics.values.sort_by { |t| -t.dwell_level }.first(limit)
              end

              def hardest_to_disengage(limit: 5)
                @topics.values.sort_by { |t| -t.disengagement_difficulty }.first(limit)
              end

              def average_dwell
                return BASE_DWELL if @topics.empty?

                vals = @topics.values.map(&:dwell_level)
                (vals.sum / vals.size).round(10)
              end

              def average_disengagement_difficulty
                return 0.0 if @topics.empty?

                vals = @topics.values.map(&:disengagement_difficulty)
                (vals.sum / vals.size).round(10)
              end

              def dwell_report
                {
                  total_topics:                     @topics.size,
                  current_topic:                    current_topic&.to_h,
                  sticky_count:                     sticky_topics.size,
                  fleeting_count:                   fleeting_topics.size,
                  ruminating_count:                 ruminating_topics.size,
                  average_dwell:                    average_dwell,
                  average_disengagement_difficulty: average_disengagement_difficulty,
                  most_engaging:                    most_engaging(limit: 3).map(&:to_h)
                }
              end

              def to_h
                {
                  total_topics:     @topics.size,
                  current_topic_id: @current_topic_id,
                  sticky_count:     sticky_topics.size,
                  ruminating_count: ruminating_topics.size,
                  average_dwell:    average_dwell
                }
              end

              private

              def prune_if_needed
                return if @topics.size < MAX_TOPICS

                least_engaged = @topics.values.min_by(&:dwell_level)
                @topics.delete(least_engaged.id) if least_engaged
              end
            end
          end
        end
      end
    end
  end
end
