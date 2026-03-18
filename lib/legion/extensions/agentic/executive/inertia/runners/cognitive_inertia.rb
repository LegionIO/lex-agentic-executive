# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module Inertia
          module Runners
            module CognitiveInertia
              include Helpers::Constants

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def form_belief(content:, engine: nil, domain: :factual, conviction: 0.5, **)
                eng = engine || default_engine
                belief = eng.form_belief(content: content, domain: domain, conviction: conviction)
                { success: true, belief: belief.to_h }
              end

              def challenge_belief(belief_id:, engine: nil, strength: 0.5, **)
                eng = engine || default_engine
                result = eng.challenge_belief(belief_id: belief_id, strength: strength)
                return { success: false, error: 'belief not found' } unless result

                { success: true, outcome: result[:outcome], belief: result[:belief].to_h }
              end

              def reinforce_belief(belief_id:, engine: nil, amount: 0.1, **)
                eng = engine || default_engine
                result = eng.reinforce_belief(belief_id: belief_id, amount: amount)
                return { success: false, error: 'belief not found' } unless result

                { success: true, belief: result.to_h }
              end

              def entrenched_beliefs(engine: nil, **)
                eng = engine || default_engine
                beliefs = eng.entrenched_beliefs.map(&:to_h)
                { success: true, beliefs: beliefs, count: beliefs.size }
              end

              def flexible_beliefs(engine: nil, **)
                eng = engine || default_engine
                beliefs = eng.flexible_beliefs.map(&:to_h)
                { success: true, beliefs: beliefs, count: beliefs.size }
              end

              def average_inertia(engine: nil, **)
                eng = engine || default_engine
                { success: true, inertia: eng.average_inertia }
              end

              def overall_flexibility(engine: nil, **)
                eng = engine || default_engine
                { success: true, flexibility: eng.overall_flexibility }
              end

              def inertia_report(engine: nil, **)
                eng = engine || default_engine
                { success: true, report: eng.inertia_report }
              end

              private

              def default_engine
                @default_engine ||= Helpers::InertiaEngine.new
              end
            end
          end
        end
      end
    end
  end
end
