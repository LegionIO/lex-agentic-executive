# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::DecisionRecord do
  let(:record) do
    described_class.new(
      id:              1,
      label:           'choose vendor',
      decision_type:   :evaluative,
      complexity:      0.7,
      quality_at_time: 0.8,
      willpower_cost:  0.035
    )
  end

  describe '#initialize' do
    it 'stores id' do
      expect(record.id).to eq(1)
    end

    it 'stores label' do
      expect(record.label).to eq('choose vendor')
    end

    it 'stores decision_type' do
      expect(record.decision_type).to eq(:evaluative)
    end

    it 'stores complexity' do
      expect(record.complexity).to eq(0.7)
    end

    it 'stores quality_at_time' do
      expect(record.quality_at_time).to eq(0.8)
    end

    it 'stores willpower_cost' do
      expect(record.willpower_cost).to eq(0.035)
    end

    it 'stores created_at as UTC Time' do
      expect(record.created_at).to be_a(Time)
    end

    it 'clamps complexity above 1.0' do
      r = described_class.new(id: 2, label: 'x', decision_type: :routine,
                              complexity: 1.5, quality_at_time: 0.5, willpower_cost: 0.05)
      expect(r.complexity).to eq(1.0)
    end

    it 'clamps complexity below 0.0' do
      r = described_class.new(id: 3, label: 'x', decision_type: :routine,
                              complexity: -0.1, quality_at_time: 0.5, willpower_cost: 0.0)
      expect(r.complexity).to eq(0.0)
    end

    it 'clamps quality_at_time to QUALITY_FLOOR minimum' do
      r = described_class.new(id: 4, label: 'x', decision_type: :routine,
                              complexity: 0.5, quality_at_time: 0.0, willpower_cost: 0.05)
      expect(r.quality_at_time).to eq(Legion::Extensions::Agentic::Executive::DecisionFatigue::Helpers::Constants::QUALITY_FLOOR)
    end
  end

  describe '#complexity_label' do
    it 'returns :complex for 0.7 complexity' do
      expect(record.complexity_label).to eq(:complex)
    end
  end

  describe '#quality_label' do
    it 'returns :good for 0.8 quality' do
      expect(record.quality_label).to eq(:good)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = record.to_h
      expect(h[:id]).to eq(1)
      expect(h[:label]).to eq('choose vendor')
      expect(h[:decision_type]).to eq(:evaluative)
      expect(h[:complexity]).to eq(0.7)
      expect(h[:complexity_label]).to eq(:complex)
      expect(h[:quality_at_time]).to eq(0.8)
      expect(h[:quality_label]).to eq(:good)
      expect(h[:willpower_cost]).to eq(0.035)
      expect(h[:created_at]).to be_a(Time)
    end
  end
end
