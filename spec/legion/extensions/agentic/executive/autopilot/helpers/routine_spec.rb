# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Autopilot::Helpers::Routine do
  subject(:routine) { described_class.new(pattern: 'check_email') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(routine.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores pattern' do
      expect(routine.pattern).to eq('check_email')
    end

    it 'defaults domain to :routine' do
      expect(routine.domain).to eq(:routine)
    end

    it 'defaults familiarity to 0.0' do
      expect(routine.familiarity).to eq(0.0)
    end

    it 'clamps familiarity' do
      high = described_class.new(pattern: 'x', familiarity: 5.0)
      expect(high.familiarity).to eq(1.0)
    end

    it 'validates domain' do
      bad = described_class.new(pattern: 'x', domain: :nonexistent)
      expect(bad.domain).to eq(:unknown)
    end

    it 'initializes execution_count to 0' do
      expect(routine.execution_count).to eq(0)
    end
  end

  describe '#execute!' do
    it 'increments execution_count' do
      routine.execute!
      expect(routine.execution_count).to eq(1)
    end

    it 'increases familiarity on success' do
      routine.execute!(success: true)
      expect(routine.familiarity).to be > 0.0
    end

    it 'decreases familiarity on failure' do
      familiar = described_class.new(pattern: 'x', familiarity: 0.5)
      familiar.execute!(success: false)
      expect(familiar.familiarity).to be < 0.5
    end

    it 'tracks success count' do
      routine.execute!(success: true)
      expect(routine.success_count).to eq(1)
    end

    it 'tracks failure count' do
      routine.execute!(success: false)
      expect(routine.failure_count).to eq(1)
    end

    it 'updates last_executed_at' do
      routine.execute!
      expect(routine.last_executed_at).to be_a(Time)
    end
  end

  describe '#decay!' do
    it 'reduces familiarity' do
      familiar = described_class.new(pattern: 'x', familiarity: 0.5)
      familiar.decay!
      expect(familiar.familiarity).to be < 0.5
    end

    it 'clamps at 0.0' do
      routine.decay!
      expect(routine.familiarity).to eq(0.0)
    end
  end

  describe '#autopilot_ready?' do
    it 'is false for new routine' do
      expect(routine.autopilot_ready?).to be false
    end

    it 'is true for highly familiar routine' do
      expert = described_class.new(pattern: 'x', familiarity: 0.8)
      expect(expert.autopilot_ready?).to be true
    end
  end

  describe '#novel?' do
    it 'is true for new routine' do
      expect(routine.novel?).to be true
    end

    it 'is false for familiar routine' do
      familiar = described_class.new(pattern: 'x', familiarity: 0.5)
      expect(familiar.novel?).to be false
    end
  end

  describe '#success_rate' do
    it 'returns 0.0 with no executions' do
      expect(routine.success_rate).to eq(0.0)
    end

    it 'returns correct rate' do
      routine.execute!(success: true)
      routine.execute!(success: false)
      expect(routine.success_rate).to eq(0.5)
    end
  end

  describe '#familiarity_label' do
    it 'returns :novel for new routine' do
      expect(routine.familiarity_label).to eq(:novel)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = routine.to_h
      expect(hash).to include(
        :id, :pattern, :domain, :familiarity, :familiarity_label,
        :autopilot_ready, :novel, :execution_count, :success_rate
      )
    end
  end
end
