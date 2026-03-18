# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::SwitchTrial do
  subject(:trial) { described_class.new(from_task_id: 'abc', to_task_id: 'def', switch_cost: 0.4, accuracy: 0.8) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(trial.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores from_task_id' do
      expect(trial.from_task_id).to eq('abc')
    end

    it 'stores to_task_id' do
      expect(trial.to_task_id).to eq('def')
    end

    it 'clamps switch_cost to [0, 1]' do
      over  = described_class.new(from_task_id: 'a', to_task_id: 'b', switch_cost: 1.5, accuracy: 0.5)
      under = described_class.new(from_task_id: 'a', to_task_id: 'b', switch_cost: -0.3, accuracy: 0.5)
      expect(over.switch_cost).to eq(1.0)
      expect(under.switch_cost).to eq(0.0)
    end

    it 'clamps accuracy to [0, 1]' do
      t = described_class.new(from_task_id: 'a', to_task_id: 'b', switch_cost: 0.3, accuracy: 2.0)
      expect(t.accuracy).to eq(1.0)
    end

    it 'sets created_at' do
      expect(trial.created_at).to be_a(Time)
    end
  end

  describe '#costly?' do
    it 'returns true when switch_cost > 0.5' do
      costly = described_class.new(from_task_id: 'a', to_task_id: 'b', switch_cost: 0.6, accuracy: 0.5)
      expect(costly.costly?).to be true
    end

    it 'returns false when switch_cost <= 0.5' do
      cheap = described_class.new(from_task_id: 'a', to_task_id: 'b', switch_cost: 0.5, accuracy: 0.5)
      expect(cheap.costly?).to be false
    end
  end

  describe '#successful?' do
    it 'returns true when accuracy > 0.7' do
      expect(trial.successful?).to be true
    end

    it 'returns false when accuracy <= 0.7' do
      poor = described_class.new(from_task_id: 'a', to_task_id: 'b', switch_cost: 0.4, accuracy: 0.7)
      expect(poor.successful?).to be false
    end
  end

  describe '#switch_cost_label' do
    it 'returns :moderate for switch_cost 0.4' do
      expect(trial.switch_cost_label).to eq(:moderate)
    end

    it 'returns :severe for switch_cost 0.9' do
      severe = described_class.new(from_task_id: 'a', to_task_id: 'b', switch_cost: 0.9, accuracy: 0.2)
      expect(severe.switch_cost_label).to eq(:severe)
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      h = trial.to_h
      expect(h).to include(:id, :from_task_id, :to_task_id, :switch_cost, :accuracy,
                           :costly, :successful, :switch_cost_label, :created_at)
    end
  end
end
