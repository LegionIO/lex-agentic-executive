# frozen_string_literal: true

require 'legion/extensions/agentic/executive/executive_function/helpers/ef_component'

RSpec.describe Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::EfComponent do
  subject(:comp) { described_class.new(name: :inhibition) }

  describe '#initialize' do
    it 'sets name' do
      expect(comp.name).to eq(:inhibition)
    end

    it 'starts with default capacity' do
      expect(comp.capacity).to eq(described_class::DEFAULT_CAPACITY)
    end

    it 'starts with zero fatigue' do
      expect(comp.fatigue).to eq(0.0)
    end

    it 'starts with empty recent_uses' do
      expect(comp.recent_uses).to be_empty
    end

    it 'clamps capacity to floor' do
      c = described_class.new(name: :shifting, capacity: -0.5)
      expect(c.capacity).to eq(described_class::CAPACITY_FLOOR)
    end

    it 'clamps capacity to ceiling' do
      c = described_class.new(name: :updating, capacity: 5.0)
      expect(c.capacity).to eq(described_class::CAPACITY_CEILING)
    end
  end

  describe '#use' do
    it 'increases fatigue by cost' do
      comp.use(cost: 0.1)
      expect(comp.fatigue).to be_within(0.001).of(0.1)
    end

    it 'records recent use entry' do
      comp.use(cost: 0.05)
      expect(comp.recent_uses.size).to eq(1)
      expect(comp.recent_uses.first[:cost]).to eq(0.05)
    end

    it 'caps fatigue at capacity' do
      comp.use(cost: 10.0)
      expect(comp.fatigue).to be <= comp.capacity
    end

    it 'retains only last 50 uses' do
      60.times { comp.use(cost: 0.0) }
      expect(comp.recent_uses.size).to eq(50)
    end
  end

  describe '#recover' do
    it 'reduces fatigue by RECOVERY_RATE' do
      comp.use(cost: 0.1)
      before = comp.fatigue
      comp.recover
      expect(comp.fatigue).to be < before
    end

    it 'does not go below zero' do
      5.times { comp.recover }
      expect(comp.fatigue).to eq(0.0)
    end
  end

  describe '#effective_capacity' do
    it 'returns capacity minus fatigue' do
      comp.use(cost: 0.2)
      expect(comp.effective_capacity).to be_within(0.001).of(comp.capacity - 0.2)
    end

    it 'never falls below CAPACITY_FLOOR' do
      comp.use(cost: 10.0)
      expect(comp.effective_capacity).to be >= described_class::CAPACITY_FLOOR
    end
  end

  describe '#fatigued?' do
    it 'returns false when fresh' do
      expect(comp.fatigued?).to be false
    end

    it 'returns true when effective_capacity is at floor' do
      comp.use(cost: comp.capacity)
      expect(comp.fatigued?).to be true
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = comp.to_h
      expect(h).to include(:name, :capacity, :fatigue, :effective_capacity, :fatigued, :recent_use_count)
    end

    it 'rounds numeric values' do
      comp.use(cost: 0.123_456_789)
      h = comp.to_h
      expect(h[:fatigue].to_s.length).to be <= 8
    end
  end
end
