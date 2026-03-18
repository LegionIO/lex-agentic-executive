# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::FatigueEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts with full willpower' do
      expect(engine.willpower).to eq(1.0)
    end

    it 'starts with zero total decisions' do
      expect(engine.total_decisions).to eq(0)
    end

    it 'records session start time' do
      expect(engine.session_start).to be_a(Time)
    end
  end

  describe '#make_decision' do
    it 'returns a DecisionRecord' do
      record = engine.make_decision(label: 'test', decision_type: :routine, complexity: 0.5)
      expect(record).to be_a(Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::DecisionRecord)
    end

    it 'increments total_decisions' do
      engine.make_decision(label: 'test', complexity: 0.5)
      expect(engine.total_decisions).to eq(1)
    end

    it 'depletes willpower' do
      engine.make_decision(label: 'test', complexity: 0.5)
      expect(engine.willpower).to be < 1.0
    end

    it 'higher complexity depletes more willpower' do
      engine1 = described_class.new
      engine2 = described_class.new
      engine1.make_decision(label: 'low', complexity: 0.1)
      engine2.make_decision(label: 'high', complexity: 0.9)
      expect(engine2.willpower).to be < engine1.willpower
    end

    it 'assigns sequential ids' do
      r1 = engine.make_decision(label: 'first', complexity: 0.3)
      r2 = engine.make_decision(label: 'second', complexity: 0.3)
      expect(r2.id).to eq(r1.id + 1)
    end

    it 'stores quality snapshot at time of decision' do
      record = engine.make_decision(label: 'test', complexity: 0.5)
      expect(record.quality_at_time).to be <= 1.0
      expect(record.quality_at_time).to be >= Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::Constants::QUALITY_FLOOR
    end

    it 'willpower does not go below QUALITY_FLOOR' do
      100.times { engine.make_decision(label: 'grind', complexity: 1.0) }
      expect(engine.willpower).to be >= Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::Constants::QUALITY_FLOOR
    end

    it 'caps stored decisions at MAX_DECISIONS' do
      (Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::Constants::MAX_DECISIONS + 10).times do
        engine.make_decision(label: 'flood', complexity: 0.0)
      end
      expect(engine.decisions_since_rest).to eq(Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::Constants::MAX_DECISIONS)
    end
  end

  describe '#current_quality' do
    it 'equals willpower after a decision' do
      engine.make_decision(label: 'test', complexity: 0.5)
      expect(engine.current_quality).to eq(engine.willpower)
    end

    it 'starts at 1.0' do
      expect(engine.current_quality).to eq(1.0)
    end
  end

  describe '#quality_label' do
    it 'returns :optimal at full willpower' do
      expect(engine.quality_label).to eq(:optimal)
    end

    it 'returns :depleted when willpower is very low' do
      20.times { engine.make_decision(label: 'x', complexity: 1.0) }
      expect(%i[depleted compromised]).to include(engine.quality_label)
    end
  end

  describe '#rest!' do
    it 'recovers willpower by RECOVERY_RATE by default' do
      engine.make_decision(label: 'x', complexity: 1.0)
      before = engine.willpower
      engine.rest!
      expect(engine.willpower).to be > before
    end

    it 'accepts a custom amount' do
      engine.make_decision(label: 'x', complexity: 1.0)
      before = engine.willpower
      engine.rest!(amount: 0.5)
      expect(engine.willpower).to be_within(0.001).of([before + 0.5, 1.0].min)
    end

    it 'does not exceed 1.0' do
      engine.rest!(amount: 5.0)
      expect(engine.willpower).to eq(1.0)
    end
  end

  describe '#full_rest!' do
    it 'restores willpower to 1.0' do
      10.times { engine.make_decision(label: 'x', complexity: 1.0) }
      engine.full_rest!
      expect(engine.willpower).to eq(1.0)
    end
  end

  describe '#decisions_since_rest' do
    it 'returns count of stored decisions' do
      3.times { engine.make_decision(label: 'x', complexity: 0.3) }
      expect(engine.decisions_since_rest).to eq(3)
    end
  end

  describe '#decision_rate' do
    it 'returns a positive float' do
      engine.make_decision(label: 'x', complexity: 0.3)
      expect(engine.decision_rate).to be > 0
    end
  end

  describe '#should_rest?' do
    it 'returns false at full willpower' do
      expect(engine.should_rest?).to be false
    end

    it 'returns true when willpower drops below 0.3' do
      engine.instance_variable_set(:@willpower, 0.2)
      expect(engine.should_rest?).to be true
    end
  end

  describe '#recent_decisions' do
    before { 5.times { |i| engine.make_decision(label: "d#{i}", complexity: 0.3) } }

    it 'returns up to limit decisions' do
      expect(engine.recent_decisions(limit: 3).size).to eq(3)
    end

    it 'returns DecisionRecord objects' do
      engine.recent_decisions.each do |r|
        expect(r).to be_a(Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::DecisionRecord)
      end
    end
  end

  describe '#decisions_by_type' do
    before do
      engine.make_decision(label: 'a', decision_type: :analytical, complexity: 0.5)
      engine.make_decision(label: 'r', decision_type: :routine, complexity: 0.2)
      engine.make_decision(label: 'a2', decision_type: :analytical, complexity: 0.5)
    end

    it 'filters by decision_type' do
      result = engine.decisions_by_type(decision_type: :analytical)
      expect(result.size).to eq(2)
    end

    it 'returns empty when no matching type' do
      expect(engine.decisions_by_type(decision_type: :creative)).to be_empty
    end
  end

  describe '#quality_trend' do
    it 'returns a float in valid range' do
      3.times { engine.make_decision(label: 'x', complexity: 0.5) }
      expect(engine.quality_trend(window: 3)).to be_between(0.0, 1.0)
    end

    it 'returns current_quality when no decisions made' do
      expect(engine.quality_trend).to eq(engine.current_quality)
    end

    it 'trends downward after many complex decisions' do
      early = engine.quality_trend(window: 5)
      10.times { engine.make_decision(label: 'hard', complexity: 1.0) }
      late = engine.quality_trend(window: 5)
      expect(late).to be <= early
    end
  end

  describe '#fatigue_report' do
    it 'returns a hash with required keys' do
      report = engine.fatigue_report
      expect(report).to include(:willpower, :current_quality, :quality_label,
                                :total_decisions, :session_decisions,
                                :decision_rate, :should_rest, :quality_trend, :session_start)
    end

    it 'should_rest is false at start' do
      expect(engine.fatigue_report[:should_rest]).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash with willpower and decisions' do
      engine.make_decision(label: 'x', complexity: 0.5)
      h = engine.to_h
      expect(h[:willpower]).to be_a(Float)
      expect(h[:decisions]).to be_an(Array)
      expect(h[:decisions].size).to eq(1)
    end
  end
end
