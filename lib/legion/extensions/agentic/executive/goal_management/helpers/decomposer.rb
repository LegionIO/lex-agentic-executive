# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            module Decomposer
              module_function

              DOMAIN_TEMPLATES = {
                safety:     ->(c) { ["diagnose: #{c}", "implement fix for: #{c}", "verify health after: #{c}"] },
                cognition:  ->(c) { ["analyze gaps in: #{c}", "design approach for: #{c}", "validate: #{c}"] },
                perception: ->(c) { ["observe current state of: #{c}", "identify patterns in: #{c}", "calibrate: #{c}"] }
              }.freeze

              def decompose(goal:, strategy: :heuristic)
                sub_goals, strategy_used = case strategy
                                           when :llm
                                             result = decompose_with_llm(goal)
                                             result ? [result, :llm] : [decompose_heuristic(goal), :heuristic]
                                           else
                                             [decompose_heuristic(goal), :heuristic]
                                           end
                { success: true, sub_goals: sub_goals, strategy_used: strategy_used }
              rescue StandardError => e
                { success: false, error: e.message }
              end

              def decompose_heuristic(goal)
                content = goal[:content].to_s.downcase
                domain  = (goal[:domain] || :general).to_sym
                steps   = decompose_by_domain(content, domain) || default_steps(content)
                steps.map { |step| { content: step, domain: domain, priority: goal[:priority] || 0.5 } }
              end

              def decompose_with_llm(goal)
                return nil unless defined?(Legion::LLM) && Legion::LLM.respond_to?(:chat)

                prompt   = build_decomposition_prompt(goal)
                response = Legion::LLM.chat(
                  caller: { extension: 'lex-agentic-executive', operation: 'decompose' }
                ).ask(prompt)
                parse_sub_goals(response.content, goal[:domain])
              rescue StandardError
                nil
              end

              def decompose_by_domain(content, domain)
                template = DOMAIN_TEMPLATES[domain]
                return nil unless template

                template.call(content)
              end

              def default_steps(content)
                [
                  "analyze current state of: #{content}",
                  "plan approach for: #{content}",
                  "execute: #{content}",
                  "verify result of: #{content}"
                ]
              end

              def build_decomposition_prompt(goal)
                <<~PROMPT
                  Decompose this goal into 2-5 concrete sub-goals. Return JSON array.
                  Goal: #{goal[:content]}
                  Domain: #{goal[:domain]}
                  Each sub-goal: {"content": "action description", "domain": "#{goal[:domain]}", "priority": 0.0-1.0}
                  Return ONLY the JSON array, no other text.
                PROMPT
              end

              def parse_sub_goals(content, domain)
                cleaned = content.gsub(/```(?:json)?\s*\n?/, '').strip
                data = ::JSON.parse(cleaned, symbolize_names: true)
                return nil unless data.is_a?(Array) && !data.empty?

                data.map do |sg|
                  {
                    content:  sg[:content].to_s,
                    domain:   (sg[:domain] || domain).to_sym,
                    priority: (sg[:priority] || 0.5).to_f.clamp(0.0, 1.0)
                  }
                end
              rescue ::JSON::ParserError
                nil
              end
            end
          end
        end
      end
    end
  end
end
