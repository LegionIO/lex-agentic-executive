# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Executive
        module GoalManagement
          module Helpers
            module Decomposer
              extend Legion::JSON::Helper if defined?(Legion::JSON::Helper)

              module_function

              def log
                Legion::Logging
              end

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
                log.info "[decomposer] decomposed goal=#{goal[:id]} strategy=#{strategy_used}"
                { success: true, sub_goals: sub_goals, strategy_used: strategy_used }
              rescue StandardError => e
                log.error "Decomposer: #{e.message}"
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
                  message: prompt,
                  caller:  { extension: 'lex-agentic-executive', operation: 'decompose' }
                )
                parse_sub_goals(extract_response_content(response, prompt), goal[:domain])
              rescue StandardError => e
                log.error "Decomposer#decompose_with_llm: #{e.message}"
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
                return nil unless content

                cleaned = content.gsub(/```(?:json)?\s*\n?/, '').strip
                data = json_load(cleaned)
                return nil unless data.is_a?(Array) && !data.empty?

                data.map do |sg|
                  {
                    content:  sg.fetch('content', sg.fetch(:content, '')).to_s,
                    domain:   sg.fetch('domain', sg.fetch(:domain, domain)).to_sym,
                    priority: sg.fetch('priority', sg.fetch(:priority, 0.5)).to_f.clamp(0.0, 1.0)
                  }
                end
              rescue StandardError => e
                log.error "Decomposer#parse_sub_goals: #{e.message}"
                nil
              end

              def extract_response_content(response, prompt)
                return response.strip if response.is_a?(String)
                return response.content if response.respond_to?(:content)

                if response.respond_to?(:ask)
                  asked = response.ask(prompt)
                  return extract_response_content(asked, prompt)
                end

                return nil unless response.is_a?(Hash)

                response[:content] || response['content'] ||
                  response.dig(:message, :content) || response.dig('message', 'content') ||
                  response[:response] || response['response']
              end
            end
          end
        end
      end
    end
  end
end
