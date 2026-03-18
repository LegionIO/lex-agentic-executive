# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::DissonanceResolution::Helpers::ResolutionEngine do
  subject(:engine) { described_class.new }

  let(:conflict) { engine.create_conflict(belief_a: 'A is true', belief_b: 'B contradicts A') }

  describe '#create_conflict' do
    it 'creates and stores a conflict' do
      c = engine.create_conflict(belief_a: 'x', belief_b: 'y')
      expect(c.id).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#apply_strategy' do
    it 'applies strategy to existing conflict' do
      result = engine.apply_strategy(conflict_id: conflict.id, strategy: :reframe,
                                     effectiveness: 0.2)
      expect(result.tension).to be < 0.5
    end

    it 'returns nil for unknown id' do
      expect(engine.apply_strategy(conflict_id: 'bad', strategy: :reframe)).to be_nil
    end

    it 'tracks strategy history' do
      engine.apply_strategy(conflict_id: conflict.id, strategy: :reframe)
      report = engine.strategy_report
      reframe = report.find { |s| s[:strategy] == :reframe }
      expect(reframe[:uses]).to eq(1)
    end
  end

  describe '#escalate_conflict' do
    it 'increases tension' do
      engine.escalate_conflict(conflict_id: conflict.id)
      expect(conflict.tension).to be > 0.5
    end
  end

  describe '#abandon_conflict' do
    it 'marks conflict as abandoned' do
      engine.abandon_conflict(conflict_id: conflict.id)
      expect(conflict.outcome).to eq(:abandoned)
    end
  end

  describe '#decay_all' do
    it 'returns count of conflicts decayed' do
      conflict
      expect(engine.decay_all).to eq(1)
    end
  end

  describe '#best_strategy' do
    it 'returns nil with no history' do
      expect(engine.best_strategy).to be_nil
    end

    it 'returns the most effective strategy' do
      c1 = engine.create_conflict(belief_a: 'a', belief_b: 'b', tension: 0.3)
      engine.apply_strategy(conflict_id: c1.id, strategy: :reframe, effectiveness: 0.5)
      c2 = engine.create_conflict(belief_a: 'c', belief_b: 'd')
      engine.apply_strategy(conflict_id: c2.id, strategy: :trivialize, effectiveness: 0.05)
      expect(engine.best_strategy).to eq(:reframe)
    end
  end

  describe '#ongoing_conflicts' do
    it 'returns only ongoing conflicts' do
      conflict
      expect(engine.ongoing_conflicts.size).to eq(1)
    end
  end

  describe '#resolved_conflicts' do
    it 'returns resolved conflicts' do
      engine.apply_strategy(conflict_id: conflict.id, strategy: :reframe, effectiveness: 0.5)
      expect(engine.resolved_conflicts.size).to eq(1)
    end
  end

  describe '#most_tense' do
    it 'returns conflicts sorted by tension desc' do
      c1 = engine.create_conflict(belief_a: 'a', belief_b: 'b', tension: 0.3)
      c2 = engine.create_conflict(belief_a: 'c', belief_b: 'd', tension: 0.9)
      result = engine.most_tense(limit: 2)
      expect(result.first.id).to eq(c2.id)
      expect(result.last.id).to eq(c1.id)
    end
  end

  describe '#resolution_rate' do
    it 'returns 0.0 with no conflicts' do
      expect(engine.resolution_rate).to eq(0.0)
    end
  end

  describe '#average_tension' do
    it 'computes average tension across conflicts' do
      engine.create_conflict(belief_a: 'a', belief_b: 'b', tension: 0.4)
      engine.create_conflict(belief_a: 'c', belief_b: 'd', tension: 0.6)
      expect(engine.average_tension).to be_within(0.01).of(0.5)
    end
  end

  describe '#dissonance_report' do
    it 'returns comprehensive report' do
      conflict
      report = engine.dissonance_report
      expect(report).to include(:total_conflicts, :ongoing, :resolved,
                                :resolution_rate, :average_tension, :best_strategy)
    end
  end

  describe '#to_h' do
    it 'returns engine stats' do
      h = engine.to_h
      expect(h).to include(:total_conflicts, :ongoing, :resolved, :resolution_rate)
    end
  end
end
