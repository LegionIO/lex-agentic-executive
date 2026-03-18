# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::LoadBalancing::Helpers::Subsystem do
  subject(:sub) { described_class.new(name: 'reasoning', subsystem_type: :reasoning) }

  describe '#initialize' do
    it 'assigns uuid id' do
      expect(sub.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with zero load' do
      expect(sub.current_load).to eq(0.0)
    end
  end

  describe '#utilization' do
    it 'returns 0.0 when no load' do
      expect(sub.utilization).to eq(0.0)
    end

    it 'increases with load' do
      sub.add_load!(amount: 0.5)
      expect(sub.utilization).to eq(0.5)
    end
  end

  describe '#load_label' do
    it 'returns :idle with no load' do
      expect(sub.load_label).to eq(:idle)
    end

    it 'returns :overloaded when near capacity' do
      sub.add_load!(amount: 0.9)
      expect(sub.load_label).to eq(:overloaded)
    end
  end

  describe '#overloaded?' do
    it 'returns false normally' do
      expect(sub.overloaded?).to be false
    end

    it 'returns true above threshold' do
      sub.add_load!(amount: 0.9)
      expect(sub.overloaded?).to be true
    end
  end

  describe '#health' do
    it 'returns 1.0 when not overloaded' do
      expect(sub.health).to eq(1.0)
    end

    it 'decreases when overloaded' do
      sub.add_load!(amount: 1.2)
      expect(sub.health).to be < 1.0
    end
  end

  describe '#add_load!' do
    it 'increases current_load' do
      sub.add_load!(amount: 0.3)
      expect(sub.current_load).to eq(0.3)
    end

    it 'increments tasks_processed' do
      sub.add_load!(amount: 0.1)
      expect(sub.tasks_processed).to eq(1)
    end
  end

  describe '#shed_load!' do
    it 'decreases current_load' do
      sub.add_load!(amount: 0.5)
      shed = sub.shed_load!(amount: 0.2)
      expect(shed).to be_within(0.01).of(0.2)
      expect(sub.current_load).to be_within(0.01).of(0.3)
    end

    it 'cannot shed more than current load' do
      sub.add_load!(amount: 0.1)
      shed = sub.shed_load!(amount: 0.5)
      expect(shed).to be_within(0.01).of(0.1)
    end
  end

  describe '#available_capacity' do
    it 'returns full capacity when empty' do
      expect(sub.available_capacity).to eq(1.0)
    end

    it 'decreases with load' do
      sub.add_load!(amount: 0.6)
      expect(sub.available_capacity).to be_within(0.01).of(0.4)
    end
  end

  describe '#to_h' do
    it 'returns complete hash' do
      h = sub.to_h
      expect(h).to include(:id, :name, :subsystem_type, :capacity, :current_load,
                           :utilization, :load_label, :overloaded, :health,
                           :available_capacity, :tasks_processed)
    end
  end
end
