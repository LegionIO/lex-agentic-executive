# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Triage::Helpers::Constants do
  describe '.label_for' do
    it 'returns :red for high triage score' do
      expect(described_class.label_for(described_class::TRIAGE_LABELS, 0.9)).to eq(:red)
    end

    it 'returns :white for low triage score' do
      expect(described_class.label_for(described_class::TRIAGE_LABELS, 0.1)).to eq(:white)
    end

    it 'returns :fresh for high capacity' do
      expect(described_class.label_for(described_class::CAPACITY_LABELS, 0.9)).to eq(:fresh)
    end

    it 'returns :overloaded for low capacity' do
      expect(described_class.label_for(described_class::CAPACITY_LABELS, 0.1)).to eq(:overloaded)
    end

    it 'returns nil for no match' do
      expect(described_class.label_for({}, 0.5)).to be_nil
    end
  end

  describe 'SEVERITY_LEVELS' do
    it 'has 5 levels' do
      expect(described_class::SEVERITY_LEVELS.size).to eq(5)
    end

    it 'includes critical' do
      expect(described_class::SEVERITY_LEVELS).to include(:critical)
    end
  end

  describe 'URGENCY_LEVELS' do
    it 'has 5 levels' do
      expect(described_class::URGENCY_LEVELS.size).to eq(5)
    end
  end
end
