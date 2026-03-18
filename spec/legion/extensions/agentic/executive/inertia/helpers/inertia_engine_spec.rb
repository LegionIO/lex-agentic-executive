# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Inertia::Helpers::InertiaEngine do
  subject(:engine) { described_class.new }

  let(:belief) { engine.form_belief(content: 'test') }

  describe '#form_belief' do
    it 'returns a Belief' do
      expect(belief).to be_a(Legion::Extensions::Agentic::Executive::Inertia::Helpers::Belief)
    end

    it 'stores the belief' do
      belief
      expect(engine.to_h[:total_beliefs]).to eq(1)
    end
  end

  describe '#challenge_belief' do
    it 'returns outcome and belief' do
      result = engine.challenge_belief(belief_id: belief.id, strength: 0.5)
      expect(result[:outcome]).to be_a(Symbol)
      expect(result[:belief]).to be_a(Legion::Extensions::Agentic::Executive::Inertia::Helpers::Belief)
    end

    it 'returns nil for unknown id' do
      expect(engine.challenge_belief(belief_id: 'fake')).to be_nil
    end
  end

  describe '#reinforce_belief' do
    it 'increases conviction' do
      original = belief.conviction
      engine.reinforce_belief(belief_id: belief.id)
      expect(belief.conviction).to be > original
    end
  end

  describe '#entrenched_beliefs' do
    it 'returns only entrenched beliefs' do
      b = engine.form_belief(content: 'strong', conviction: 0.9)
      10.times { engine.reinforce_belief(belief_id: b.id) }
      expect(engine.entrenched_beliefs).to include(b)
    end
  end

  describe '#beliefs_by_domain' do
    it 'filters by domain' do
      engine.form_belief(content: 'causal', domain: :causal)
      engine.form_belief(content: 'factual', domain: :factual)
      result = engine.beliefs_by_domain(domain: :causal)
      expect(result.size).to eq(1)
    end
  end

  describe '#average_inertia' do
    it 'returns default with no beliefs' do
      default = Legion::Extensions::Agentic::Executive::Inertia::Helpers::Constants::DEFAULT_INERTIA
      expect(engine.average_inertia).to eq(default)
    end
  end

  describe '#overall_flexibility' do
    it 'returns 0.5 with no beliefs' do
      expect(engine.overall_flexibility).to eq(0.5)
    end

    it 'is inverse of average inertia' do
      belief
      expect(engine.overall_flexibility).to eq((1.0 - engine.average_inertia).round(10))
    end
  end

  describe '#inertia_report' do
    it 'includes all report fields' do
      belief
      report = engine.inertia_report
      expect(report).to include(
        :total_beliefs, :entrenched_count, :flexible_count,
        :average_inertia, :average_conviction, :overall_flexibility,
        :most_resistant
      )
    end
  end

  describe '#to_h' do
    it 'includes summary fields' do
      hash = engine.to_h
      expect(hash).to include(
        :total_beliefs, :entrenched_count, :flexible_count,
        :average_inertia, :overall_flexibility
      )
    end
  end

  describe 'pruning' do
    it 'prunes most flexible belief when limit reached' do
      stub_const('Legion::Extensions::Agentic::Executive::Inertia::Helpers::Constants::MAX_BELIEFS', 3)
      eng = described_class.new
      4.times { |i| eng.form_belief(content: "b#{i}") }
      expect(eng.to_h[:total_beliefs]).to eq(3)
    end
  end
end
