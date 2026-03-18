# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Executive
        module Dwell
          module Helpers
            class DwellTopic
              include Constants

              attr_reader :id, :content, :topic_type, :salience, :novelty,
                          :emotional_intensity, :complexity, :dwell_level,
                          :engagement_count, :created_at

              def initialize(content:, topic_type: :concept, salience: 0.5,
                             novelty: 0.5, emotional_intensity: 0.3, complexity: 0.5)
                @id                  = SecureRandom.uuid
                @content             = content
                @topic_type          = topic_type.to_sym
                @salience            = salience.to_f.clamp(0.0, 1.0).round(10)
                @novelty             = novelty.to_f.clamp(0.0, 1.0).round(10)
                @emotional_intensity = emotional_intensity.to_f.clamp(0.0, 1.0).round(10)
                @complexity          = complexity.to_f.clamp(0.0, 1.0).round(10)
                @dwell_level         = compute_initial_dwell
                @engagement_count    = 0
                @created_at          = Time.now.utc
              end

              def engage!
                @engagement_count += 1
                @dwell_level = (@dwell_level + ENGAGEMENT_BOOST).clamp(0.0, 1.0).round(10)
                self
              end

              def decay!
                @dwell_level = (@dwell_level - DWELL_DECAY).clamp(0.0, 1.0).round(10)
                @novelty = (@novelty - 0.02).clamp(0.0, 1.0).round(10)
                self
              end

              def disengage!(force: 0.0)
                reduction = (0.1 + force).clamp(0.0, 1.0)
                @dwell_level = (@dwell_level - reduction).clamp(0.0, 1.0).round(10)
                self
              end

              def sticky?
                @dwell_level >= STICKY_THRESHOLD
              end

              def fleeting?
                @dwell_level <= FLEETING_THRESHOLD
              end

              def ruminating?
                @dwell_level >= RUMINATION_THRESHOLD
              end

              def disengagement_difficulty
                ((@emotional_intensity * 0.4) + (@dwell_level * 0.4) + (@complexity * 0.2)).round(10)
              end

              def dwell_label
                match = DWELL_LABELS.find { |range, _| range.cover?(@dwell_level) }
                match ? match.last : :fleeting
              end

              def engagement_label
                score = ((@dwell_level * 0.6) + (@salience * 0.4)).round(10)
                match = ENGAGEMENT_LABELS.find { |range, _| range.cover?(score) }
                match ? match.last : :disengaged
              end

              def disengage_label
                match = DISENGAGE_LABELS.find { |range, _| range.cover?(disengagement_difficulty) }
                match ? match.last : :effortless
              end

              def to_h
                {
                  id:                       @id,
                  content:                  @content,
                  topic_type:               @topic_type,
                  salience:                 @salience,
                  novelty:                  @novelty,
                  emotional_intensity:      @emotional_intensity,
                  complexity:               @complexity,
                  dwell_level:              @dwell_level,
                  dwell_label:              dwell_label,
                  sticky:                   sticky?,
                  fleeting:                 fleeting?,
                  ruminating:               ruminating?,
                  disengagement_difficulty: disengagement_difficulty,
                  disengage_label:          disengage_label,
                  engagement_count:         @engagement_count,
                  engagement_label:         engagement_label,
                  created_at:               @created_at
                }
              end

              private

              def compute_initial_dwell
                (BASE_DWELL +
                 (@salience * SALIENCE_WEIGHT) +
                 (@novelty * NOVELTY_WEIGHT) +
                 (@emotional_intensity * EMOTION_WEIGHT) +
                 (@complexity * COMPLEXITY_WEIGHT)).clamp(0.0, 1.0).round(10)
              end
            end
          end
        end
      end
    end
  end
end
