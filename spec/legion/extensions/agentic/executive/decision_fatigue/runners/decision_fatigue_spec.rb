# frozen_string_literal: true

require 'legion/extensions/agentic/executive/decision_fatigue/client'

RSpec.describe Legion::Extensions::Agentic::Executive::DecisionFatigue::Runners::DecisionFatigue do
  let(:client) { Legion::Extensions::Agentic::Executive::DecisionFatigue::Client.new }

  describe '#make_decision' do
    it 'returns a hash with decision fields' do
      result = client.make_decision(label: 'pick framework', decision_type: :analytical, complexity: 0.6)
      expect(result[:label]).to eq('pick framework')
      expect(result[:decision_type]).to eq(:analytical)
      expect(result[:complexity]).to eq(0.6)
      expect(result[:quality_at_time]).to be_a(Float)
      expect(result[:willpower_cost]).to be_a(Float)
    end

    it 'uses default decision_type :routine when not provided' do
      result = client.make_decision(label: 'x', complexity: 0.3)
      expect(result[:decision_type]).to eq(:routine)
    end

    it 'uses default complexity 0.5 when not provided' do
      result = client.make_decision(label: 'x')
      expect(result[:complexity]).to eq(0.5)
    end

    it 'assigns sequential ids across calls' do
      r1 = client.make_decision(label: 'first')
      r2 = client.make_decision(label: 'second')
      expect(r2[:id]).to eq(r1[:id] + 1)
    end

    it 'quality_at_time is within valid range' do
      result = client.make_decision(label: 'x', complexity: 0.5)
      expect(result[:quality_at_time]).to be_between(0.2, 1.0)
    end

    it 'accepts keyword splat extras without error' do
      expect { client.make_decision(label: 'x', complexity: 0.3, extra: :ignored) }.not_to raise_error
    end
  end

  describe '#fatigue_status' do
    it 'returns willpower' do
      result = client.fatigue_status
      expect(result[:willpower]).to be_a(Float)
    end

    it 'returns quality_label symbol' do
      result = client.fatigue_status
      expect(result[:quality_label]).to be_a(Symbol)
    end

    it 'returns should_rest boolean' do
      result = client.fatigue_status
      expect(result[:should_rest]).to be(true).or be(false)
    end

    it 'total_decisions starts at 0' do
      expect(client.fatigue_status[:total_decisions]).to eq(0)
    end

    it 'total_decisions increases after make_decision' do
      client.make_decision(label: 'x')
      expect(client.fatigue_status[:total_decisions]).to eq(1)
    end
  end

  describe '#rest' do
    before { client.make_decision(label: 'x', complexity: 1.0) }

    it 'returns recovered amount' do
      result = client.rest
      expect(result[:recovered]).to be_a(Float)
    end

    it 'returns updated willpower' do
      result = client.rest
      expect(result[:willpower]).to be_a(Float)
    end

    it 'returns quality_label' do
      result = client.rest
      expect(result[:quality_label]).to be_a(Symbol)
    end

    it 'accepts custom amount' do
      before_wp = client.fatigue_status[:willpower]
      client.rest(amount: 0.5)
      after_wp = client.fatigue_status[:willpower]
      expect(after_wp).to be >= before_wp
    end
  end

  describe '#full_rest' do
    before { 5.times { client.make_decision(label: 'grind', complexity: 1.0) } }

    it 'restores willpower to 1.0' do
      result = client.full_rest
      expect(result[:willpower]).to eq(1.0)
    end

    it 'returns quality_label :optimal' do
      result = client.full_rest
      expect(result[:quality_label]).to eq(:optimal)
    end

    it 'returns recovered amount' do
      result = client.full_rest
      expect(result[:recovered]).to be >= 0
    end
  end

  describe '#recent_decisions' do
    before { 5.times { |i| client.make_decision(label: "d#{i}", complexity: 0.3) } }

    it 'returns decisions array and count' do
      result = client.recent_decisions(limit: 3)
      expect(result[:count]).to eq(3)
      expect(result[:decisions].size).to eq(3)
    end

    it 'each decision has expected keys' do
      result = client.recent_decisions(limit: 2)
      result[:decisions].each do |d|
        expect(d).to include(:id, :label, :decision_type, :complexity, :quality_at_time)
      end
    end
  end

  describe '#decisions_by_type' do
    before do
      client.make_decision(label: 'a', decision_type: :analytical, complexity: 0.5)
      client.make_decision(label: 'r', decision_type: :routine, complexity: 0.2)
      client.make_decision(label: 'a2', decision_type: :analytical, complexity: 0.6)
    end

    it 'returns only decisions of the given type' do
      result = client.decisions_by_type(decision_type: :analytical)
      expect(result[:count]).to eq(2)
      expect(result[:decision_type]).to eq(:analytical)
    end

    it 'returns empty array for unused type' do
      result = client.decisions_by_type(decision_type: :creative)
      expect(result[:count]).to eq(0)
      expect(result[:decisions]).to be_empty
    end
  end

  describe '#quality_trend' do
    it 'returns trend float and label' do
      client.make_decision(label: 'x', complexity: 0.5)
      result = client.quality_trend(window: 5)
      expect(result[:trend]).to be_a(Float)
      expect(result[:label]).to be_a(Symbol)
      expect(result[:window]).to eq(5)
    end

    it 'trend degrades with many high-complexity decisions' do
      early = client.quality_trend(window: 5)[:trend]
      15.times { client.make_decision(label: 'hard', complexity: 1.0) }
      late = client.quality_trend(window: 5)[:trend]
      expect(late).to be <= early
    end
  end

  describe '#should_rest' do
    it 'returns should_rest boolean and willpower' do
      result = client.should_rest
      expect(result[:should_rest]).to be(true).or be(false)
      expect(result[:willpower]).to be_a(Float)
    end

    it 'is false at start' do
      expect(client.should_rest[:should_rest]).to be false
    end
  end
end
