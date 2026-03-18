# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::DissonanceResolution::Helpers::DissonanceConflict do
  subject(:conflict) do
    described_class.new(belief_a: 'smoking is harmful', belief_b: 'I smoke', domain: :health)
  end

  describe '#initialize' do
    it 'assigns uuid id' do
      expect(conflict.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores beliefs and domain' do
      expect(conflict.belief_a).to eq('smoking is harmful')
      expect(conflict.belief_b).to eq('I smoke')
      expect(conflict.domain).to eq(:health)
    end

    it 'starts with default tension' do
      expect(conflict.tension).to eq(0.5)
    end

    it 'starts as ongoing' do
      expect(conflict.outcome).to eq(:ongoing)
    end
  end

  describe '#tension_label' do
    it 'returns :uncomfortable for default tension' do
      expect(conflict.tension_label).to eq(:uncomfortable)
    end
  end

  describe '#resolved?' do
    it 'returns false when tension above threshold' do
      expect(conflict.resolved?).to be false
    end

    it 'returns true when tension below threshold' do
      conflict.apply_strategy!(strategy: :rationalize, effectiveness: 0.4)
      expect(conflict.resolved?).to be true
    end
  end

  describe '#apply_strategy!' do
    it 'reduces tension' do
      before = conflict.tension
      conflict.apply_strategy!(strategy: :reframe, effectiveness: 0.2)
      expect(conflict.tension).to be < before
    end

    it 'records strategy used' do
      conflict.apply_strategy!(strategy: :belief_change, effectiveness: 0.1)
      expect(conflict.strategy_used).to eq(:belief_change)
    end

    it 'increments attempts' do
      conflict.apply_strategy!(strategy: :trivialize, effectiveness: 0.1)
      expect(conflict.attempts).to eq(1)
    end

    it 'marks resolved when tension drops below threshold' do
      conflict.apply_strategy!(strategy: :reframe, effectiveness: 0.5)
      expect(conflict.outcome).to eq(:resolved)
      expect(conflict.resolved_at).not_to be_nil
    end
  end

  describe '#escalate!' do
    it 'increases tension' do
      before = conflict.tension
      conflict.escalate!
      expect(conflict.tension).to be > before
    end

    it 'marks escalated at high tension' do
      high = described_class.new(belief_a: 'a', belief_b: 'b', tension: 0.85)
      high.escalate!(amount: 0.1)
      expect(high.outcome).to eq(:escalated)
    end
  end

  describe '#decay!' do
    it 'reduces tension slightly' do
      before = conflict.tension
      conflict.decay!
      expect(conflict.tension).to be < before
    end
  end

  describe '#abandon!' do
    it 'sets outcome to abandoned' do
      conflict.abandon!
      expect(conflict.outcome).to eq(:abandoned)
      expect(conflict.resolved_at).not_to be_nil
    end
  end

  describe '#to_h' do
    it 'returns complete hash' do
      h = conflict.to_h
      expect(h).to include(:id, :belief_a, :belief_b, :domain, :tension,
                           :tension_label, :resolved, :strategy_used, :outcome,
                           :attempts, :created_at)
    end
  end
end
