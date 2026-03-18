# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Autopilot::Helpers::Constants do
  describe '.label_for' do
    it 'returns :expert for high familiarity' do
      expect(described_class.label_for(described_class::FAMILIARITY_LABELS, 0.9)).to eq(:expert)
    end

    it 'returns :novel for low familiarity' do
      expect(described_class.label_for(described_class::FAMILIARITY_LABELS, 0.1)).to eq(:novel)
    end

    it 'returns :energized for high energy' do
      expect(described_class.label_for(described_class::ENERGY_LABELS, 0.9)).to eq(:energized)
    end

    it 'returns :exhausted for low energy' do
      expect(described_class.label_for(described_class::ENERGY_LABELS, 0.1)).to eq(:exhausted)
    end

    it 'returns nil for empty labels' do
      expect(described_class.label_for({}, 0.5)).to be_nil
    end
  end

  describe 'TASK_DOMAINS' do
    it 'has 8 domains' do
      expect(described_class::TASK_DOMAINS.size).to eq(8)
    end
  end

  describe 'PROCESSING_MODES' do
    it 'has 3 modes' do
      expect(described_class::PROCESSING_MODES.size).to eq(3)
    end
  end
end
