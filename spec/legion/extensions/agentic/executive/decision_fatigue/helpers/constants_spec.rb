# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::Constants do
  describe 'constants' do
    it 'defines MAX_DECISIONS' do
      expect(described_module::MAX_DECISIONS).to eq(500)
    end

    it 'defines DEFAULT_WILLPOWER' do
      expect(described_module::DEFAULT_WILLPOWER).to eq(1.0)
    end

    it 'defines DEPLETION_RATE' do
      expect(described_module::DEPLETION_RATE).to eq(0.05)
    end

    it 'defines RECOVERY_RATE' do
      expect(described_module::RECOVERY_RATE).to eq(0.08)
    end

    it 'defines QUALITY_FLOOR' do
      expect(described_module::QUALITY_FLOOR).to eq(0.2)
    end

    it 'defines all DECISION_TYPES' do
      expect(described_module::DECISION_TYPES).to include(:analytical, :evaluative, :creative, :routine, :social, :moral)
    end

    it 'has 6 decision types' do
      expect(described_module::DECISION_TYPES.size).to eq(6)
    end

    it 'has 5 quality labels' do
      expect(described_module::QUALITY_LABELS.size).to eq(5)
    end

    it 'has 5 complexity labels' do
      expect(described_module::COMPLEXITY_LABELS.size).to eq(5)
    end
  end

  describe '.quality_label_for' do
    it 'returns :optimal for high willpower' do
      expect(described_module.quality_label_for(0.95)).to eq(:optimal)
    end

    it 'returns :good for above 0.65' do
      expect(described_module.quality_label_for(0.75)).to eq(:good)
    end

    it 'returns :adequate for mid-range' do
      expect(described_module.quality_label_for(0.55)).to eq(:adequate)
    end

    it 'returns :compromised for low willpower' do
      expect(described_module.quality_label_for(0.35)).to eq(:compromised)
    end

    it 'returns :depleted for very low willpower' do
      expect(described_module.quality_label_for(0.1)).to eq(:depleted)
    end

    it 'returns :depleted for exactly 0.0' do
      expect(described_module.quality_label_for(0.0)).to eq(:depleted)
    end
  end

  describe '.complexity_label_for' do
    it 'returns :trivial for very low complexity' do
      expect(described_module.complexity_label_for(0.1)).to eq(:trivial)
    end

    it 'returns :simple for low complexity' do
      expect(described_module.complexity_label_for(0.3)).to eq(:simple)
    end

    it 'returns :moderate for mid complexity' do
      expect(described_module.complexity_label_for(0.5)).to eq(:moderate)
    end

    it 'returns :complex for high complexity' do
      expect(described_module.complexity_label_for(0.7)).to eq(:complex)
    end

    it 'returns :overwhelming for very high complexity' do
      expect(described_module.complexity_label_for(0.9)).to eq(:overwhelming)
    end
  end

  def described_module
    Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::Constants
  end
end
