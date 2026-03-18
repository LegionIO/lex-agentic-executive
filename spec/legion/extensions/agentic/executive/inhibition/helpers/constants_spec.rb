# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants do
  describe 'IMPULSE_TYPES' do
    it 'defines 5 types' do
      expect(described_class::IMPULSE_TYPES.size).to eq(5)
    end

    it 'includes reactive' do
      expect(described_class::IMPULSE_TYPES).to include(:reactive)
    end

    it 'includes emotional' do
      expect(described_class::IMPULSE_TYPES).to include(:emotional)
    end

    it 'is frozen' do
      expect(described_class::IMPULSE_TYPES).to be_frozen
    end
  end

  describe 'INHIBITION_STRATEGIES' do
    it 'defines 5 strategies' do
      expect(described_class::INHIBITION_STRATEGIES.size).to eq(5)
    end

    it 'includes suppression' do
      expect(described_class::INHIBITION_STRATEGIES).to include(:suppression)
    end

    it 'includes delay' do
      expect(described_class::INHIBITION_STRATEGIES).to include(:delay)
    end

    it 'is frozen' do
      expect(described_class::INHIBITION_STRATEGIES).to be_frozen
    end
  end

  describe 'IMPULSE_STRENGTHS' do
    it 'defines 5 strength levels' do
      expect(described_class::IMPULSE_STRENGTHS.size).to eq(5)
    end

    it 'has overwhelming at 1.0' do
      expect(described_class::IMPULSE_STRENGTHS[:overwhelming]).to eq(1.0)
    end

    it 'has negligible as the lowest' do
      expect(described_class::IMPULSE_STRENGTHS[:negligible]).to eq(0.1)
    end

    it 'has values in descending order' do
      values = described_class::IMPULSE_STRENGTHS.values
      expect(values).to eq(values.sort.reverse)
    end

    it 'is frozen' do
      expect(described_class::IMPULSE_STRENGTHS).to be_frozen
    end
  end

  describe 'numeric constants' do
    it 'defines INHIBITION_ALPHA' do
      expect(described_class::INHIBITION_ALPHA).to eq(0.12)
    end

    it 'defines FATIGUE_PER_INHIBITION' do
      expect(described_class::FATIGUE_PER_INHIBITION).to eq(0.05)
    end

    it 'defines FATIGUE_RECOVERY_RATE' do
      expect(described_class::FATIGUE_RECOVERY_RATE).to eq(0.02)
    end

    it 'defines MAX_INHIBITION_LOG' do
      expect(described_class::MAX_INHIBITION_LOG).to eq(200)
    end

    it 'defines WILLPOWER_THRESHOLD' do
      expect(described_class::WILLPOWER_THRESHOLD).to eq(0.3)
    end

    it 'defines AUTOMATIC_SUPPRESS_THRESHOLD' do
      expect(described_class::AUTOMATIC_SUPPRESS_THRESHOLD).to eq(0.2)
    end

    it 'defines DELAY_DISCOUNT_RATE' do
      expect(described_class::DELAY_DISCOUNT_RATE).to eq(0.1)
    end

    it 'defines STROOP_CONFLICT_THRESHOLD' do
      expect(described_class::STROOP_CONFLICT_THRESHOLD).to eq(0.6)
    end
  end

  describe 'threshold relationships' do
    it 'has AUTOMATIC_SUPPRESS below WILLPOWER_THRESHOLD' do
      expect(described_class::AUTOMATIC_SUPPRESS_THRESHOLD).to be < described_class::WILLPOWER_THRESHOLD
    end

    it 'has WILLPOWER_THRESHOLD below 1.0' do
      expect(described_class::WILLPOWER_THRESHOLD).to be < 1.0
    end
  end
end
