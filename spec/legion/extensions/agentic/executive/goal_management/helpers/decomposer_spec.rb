# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::Decomposer do
  describe '.decompose' do
    let(:goal_hash) do
      { id: 'goal-001', content: 'fix degraded safety monitor', domain: :safety, priority: 0.7, status: :active }
    end

    context 'with heuristic strategy' do
      it 'returns sub-goals array' do
        result = described_class.decompose(goal: goal_hash, strategy: :heuristic)
        expect(result[:success]).to be true
        expect(result[:sub_goals]).to be_an(Array)
        expect(result[:sub_goals]).not_to be_empty
        expect(result[:sub_goals].first).to have_key(:content)
        expect(result[:sub_goals].first).to have_key(:domain)
      end

      it 'preserves parent domain' do
        result = described_class.decompose(goal: goal_hash, strategy: :heuristic)
        result[:sub_goals].each { |sg| expect(sg[:domain]).to eq(:safety) }
      end

      it 'reports heuristic as strategy_used' do
        result = described_class.decompose(goal: goal_hash, strategy: :heuristic)
        expect(result[:strategy_used]).to eq(:heuristic)
      end
    end

    context 'with llm strategy when llm unavailable' do
      it 'falls back to heuristic' do
        result = described_class.decompose(goal: goal_hash, strategy: :llm)
        expect(result[:success]).to be true
        expect(result[:strategy_used]).to eq(:heuristic)
      end

      it 'parses native hash responses from Legion::LLM.chat' do
        llm = Module.new
        llm.define_singleton_method(:chat) do |message:, **|
          raise 'missing prompt' if message.to_s.empty?

          { content: '[{"content":"inspect controls","domain":"safety","priority":0.8}]' }
        end
        stub_const('Legion::LLM', llm)

        result = described_class.decompose(goal: goal_hash, strategy: :llm)

        expect(result[:strategy_used]).to eq(:llm)
        expect(result[:sub_goals].first[:content]).to eq('inspect controls')
      end
    end

    context 'with default strategy' do
      it 'uses heuristic when strategy is omitted' do
        result = described_class.decompose(goal: goal_hash)
        expect(result[:success]).to be true
        expect(result[:strategy_used]).to eq(:heuristic)
      end
    end
  end

  describe '.decompose_heuristic' do
    context 'with a known domain' do
      it 'uses the safety domain template' do
        goal = { content: 'monitor failure', domain: :safety, priority: 0.8 }
        steps = described_class.decompose_heuristic(goal)
        expect(steps.size).to eq(3)
        expect(steps.map { |s| s[:content] }).to all(be_a(String))
      end

      it 'uses the cognition domain template' do
        goal = { content: 'knowledge gap', domain: :cognition, priority: 0.6 }
        steps = described_class.decompose_heuristic(goal)
        expect(steps.size).to eq(3)
      end

      it 'uses the perception domain template' do
        goal = { content: 'sensor drift', domain: :perception, priority: 0.5 }
        steps = described_class.decompose_heuristic(goal)
        expect(steps.size).to eq(3)
      end
    end

    context 'with an unknown domain' do
      it 'falls back to default four-step template' do
        goal = { content: 'unknown task', domain: :general, priority: 0.5 }
        steps = described_class.decompose_heuristic(goal)
        expect(steps.size).to eq(4)
      end
    end

    it 'sets priority from parent goal' do
      goal = { content: 'some task', domain: :safety, priority: 0.9 }
      steps = described_class.decompose_heuristic(goal)
      steps.each { |s| expect(s[:priority]).to eq(0.9) }
    end

    it 'defaults priority to 0.5 when not provided' do
      goal = { content: 'some task', domain: :general }
      steps = described_class.decompose_heuristic(goal)
      steps.each { |s| expect(s[:priority]).to eq(0.5) }
    end
  end

  describe '.decompose_by_domain' do
    it 'returns nil for unknown domain' do
      result = described_class.decompose_by_domain('content', :unknown)
      expect(result).to be_nil
    end

    it 'returns array of strings for known domain' do
      result = described_class.decompose_by_domain('test content', :safety)
      expect(result).to be_an(Array)
      expect(result).to all(be_a(String))
    end
  end

  describe '.default_steps' do
    it 'returns four steps' do
      steps = described_class.default_steps('do something')
      expect(steps.size).to eq(4)
    end

    it 'interpolates content into each step' do
      steps = described_class.default_steps('repair the system')
      expect(steps).to all(include('repair the system'))
    end
  end

  describe '.parse_sub_goals' do
    it 'parses valid JSON array' do
      json = '[{"content":"step one","domain":"safety","priority":0.8}]'
      result = described_class.parse_sub_goals(json, :safety)
      expect(result).to be_an(Array)
      expect(result.first[:content]).to eq('step one')
      expect(result.first[:domain]).to eq(:safety)
      expect(result.first[:priority]).to eq(0.8)
    end

    it 'returns nil for invalid JSON' do
      expect(described_class.parse_sub_goals('not json', :general)).to be_nil
    end

    it 'returns nil for empty array' do
      expect(described_class.parse_sub_goals('[]', :general)).to be_nil
    end

    it 'strips markdown code fences' do
      json = "```json\n[{\"content\":\"step\",\"domain\":\"general\",\"priority\":0.5}]\n```"
      result = described_class.parse_sub_goals(json, :general)
      expect(result).not_to be_nil
      expect(result.first[:content]).to eq('step')
    end

    it 'clamps priority to 0.0..1.0' do
      json = '[{"content":"x","priority":2.5}]'
      result = described_class.parse_sub_goals(json, :general)
      expect(result.first[:priority]).to eq(1.0)
    end

    it 'uses fallback domain when sub-goal omits domain' do
      json = '[{"content":"x"}]'
      result = described_class.parse_sub_goals(json, :cognition)
      expect(result.first[:domain]).to eq(:cognition)
    end
  end
end
