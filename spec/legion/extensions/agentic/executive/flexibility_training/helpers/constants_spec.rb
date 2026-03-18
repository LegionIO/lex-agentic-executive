# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::Constants do
  describe 'DIFFICULTY_LEVELS' do
    it 'has 5 levels in order' do
      expect(described_class::DIFFICULTY_LEVELS).to eq(%i[trivial easy moderate hard extreme])
    end
  end

  describe 'TASK_DOMAINS' do
    it 'includes expected cognitive domains' do
      expect(described_class::TASK_DOMAINS).to include(:linguistic, :spatial, :numerical, :logical)
    end

    it 'has 7 domains' do
      expect(described_class::TASK_DOMAINS.size).to eq(7)
    end
  end

  describe 'SWITCH_COST_LABELS' do
    it 'maps 0.9 to :severe' do
      expect(described_class.label_for(0.9, described_class::SWITCH_COST_LABELS)).to eq(:severe)
    end

    it 'maps 0.7 to :high' do
      expect(described_class.label_for(0.7, described_class::SWITCH_COST_LABELS)).to eq(:high)
    end

    it 'maps 0.5 to :moderate' do
      expect(described_class.label_for(0.5, described_class::SWITCH_COST_LABELS)).to eq(:moderate)
    end

    it 'maps 0.3 to :low' do
      expect(described_class.label_for(0.3, described_class::SWITCH_COST_LABELS)).to eq(:low)
    end

    it 'maps 0.1 to :minimal' do
      expect(described_class.label_for(0.1, described_class::SWITCH_COST_LABELS)).to eq(:minimal)
    end
  end

  describe 'FLEXIBILITY_LABELS' do
    it 'maps 0.9 to :highly_flexible' do
      expect(described_class.label_for(0.9, described_class::FLEXIBILITY_LABELS)).to eq(:highly_flexible)
    end

    it 'maps 0.1 to :inflexible' do
      expect(described_class.label_for(0.1, described_class::FLEXIBILITY_LABELS)).to eq(:inflexible)
    end
  end

  describe 'PROGRESS_LABELS' do
    it 'maps 0.9 to :mastered' do
      expect(described_class.label_for(0.9, described_class::PROGRESS_LABELS)).to eq(:mastered)
    end

    it 'maps 0.05 to :beginner' do
      expect(described_class.label_for(0.05, described_class::PROGRESS_LABELS)).to eq(:beginner)
    end
  end

  describe '.label_for' do
    it 'returns nil when value matches no range' do
      expect(described_class.label_for(0.5, {})).to be_nil
    end
  end
end
