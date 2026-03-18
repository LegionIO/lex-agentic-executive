# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Dwell
          module Runners
            module CognitiveDwell
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def add_topic(content:, topic_type: :concept, salience: 0.5,
                            novelty: 0.5, emotional_intensity: 0.3, complexity: 0.5, engine: nil, **)
                eng = engine || default_engine
                topic = eng.add_topic(content: content, topic_type: topic_type, salience: salience,
                                      novelty: novelty, emotional_intensity: emotional_intensity,
                                      complexity: complexity)
                { success: true, topic: topic.to_h }
              end

              def focus_on(topic_id:, engine: nil, **)
                eng = engine || default_engine
                topic = eng.focus_on(topic_id: topic_id)
                return { success: false, error: 'topic not found' } unless topic

                { success: true, topic: topic.to_h }
              end

              def disengage(topic_id:, force: 0.0, engine: nil, **)
                eng = engine || default_engine
                topic = eng.disengage(topic_id: topic_id, force: force)
                return { success: false, error: 'topic not found' } unless topic

                { success: true, topic: topic.to_h }
              end

              def decay(engine: nil, **)
                eng = engine || default_engine
                result = eng.decay_all!
                { success: true, **result }
              end

              def current_topic(engine: nil, **)
                eng = engine || default_engine
                topic = eng.current_topic
                return { success: false, error: 'no current topic' } unless topic

                { success: true, topic: topic.to_h }
              end

              def sticky_topics(engine: nil, **)
                eng = engine || default_engine
                { success: true, topics: eng.sticky_topics.map(&:to_h) }
              end

              def ruminating_topics(engine: nil, **)
                eng = engine || default_engine
                { success: true, topics: eng.ruminating_topics.map(&:to_h) }
              end

              def most_engaging(limit: 5, engine: nil, **)
                eng = engine || default_engine
                { success: true, topics: eng.most_engaging(limit: limit).map(&:to_h) }
              end

              def dwell_report(engine: nil, **)
                eng = engine || default_engine
                { success: true, report: eng.dwell_report }
              end

              def status(engine: nil, **)
                eng = engine || default_engine
                { success: true, **eng.to_h }
              end

              private

              def default_engine
                @default_engine ||= Helpers::DwellEngine.new
              end
            end
          end
        end
      end
    end
  end
end
