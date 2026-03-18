# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Dwell
          module Helpers
            module Constants
              MAX_TOPICS = 200
              MAX_DWELL_HISTORY = 500

              # Dwell dynamics
              BASE_DWELL = 0.3
              SALIENCE_WEIGHT = 0.25
              NOVELTY_WEIGHT = 0.25
              EMOTION_WEIGHT = 0.3
              COMPLEXITY_WEIGHT = 0.2
              DWELL_DECAY = 0.05
              ENGAGEMENT_BOOST = 0.08

              # Thresholds
              STICKY_THRESHOLD = 0.7
              FLEETING_THRESHOLD = 0.2
              RUMINATION_THRESHOLD = 0.9

              # Topic types
              TOPIC_TYPES = %i[
                problem concept conversation task memory
                emotion plan decision observation
              ].freeze

              # Dwell duration labels
              DWELL_LABELS = {
                (0.8..)     => :stuck,
                (0.6...0.8) => :engrossed,
                (0.4...0.6) => :attending,
                (0.2...0.4) => :browsing,
                (..0.2)     => :fleeting
              }.freeze

              # Engagement labels
              ENGAGEMENT_LABELS = {
                (0.8..)     => :deeply_engaged,
                (0.6...0.8) => :engaged,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :light,
                (..0.2)     => :disengaged
              }.freeze

              # Disengagement difficulty labels
              DISENGAGE_LABELS = {
                (0.8..)     => :very_hard,
                (0.6...0.8) => :hard,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :easy,
                (..0.2)     => :effortless
              }.freeze
            end
          end
        end
      end
    end
  end
end
