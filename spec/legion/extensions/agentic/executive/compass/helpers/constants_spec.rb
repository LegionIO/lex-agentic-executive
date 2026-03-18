# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Compass::Helpers::Constants do
  describe 'CARDINAL_DIRECTIONS' do
    it 'maps four cardinal points to value axes' do
      expect(described_class::CARDINAL_DIRECTIONS.keys).to eq(%i[north east south west])
    end

    it 'maps north to truth' do
      expect(described_class::CARDINAL_DIRECTIONS[:north]).to eq(:truth)
    end
  end

  describe 'INTERCARDINAL_DIRECTIONS' do
    it 'has four intercardinal points' do
      expect(described_class::INTERCARDINAL_DIRECTIONS.size).to eq(4)
    end

    it 'blends two value axes per direction' do
      expect(described_class::INTERCARDINAL_DIRECTIONS[:northeast]).to eq(%i[truth utility])
    end
  end

  describe 'BIAS_TYPES' do
    it 'includes common cognitive biases' do
      %i[confirmation anchoring availability].each do |b|
        expect(described_class::BIAS_TYPES).to include(b)
      end
    end
  end

  describe '.label_for' do
    it 'returns precise for high accuracy' do
      expect(described_class.label_for(described_class::ACCURACY_LABELS, 0.9)).to eq(:precise)
    end

    it 'returns lost for low accuracy' do
      expect(described_class.label_for(described_class::ACCURACY_LABELS, 0.1)).to eq(:lost)
    end

    it 'returns severe for high declination' do
      expect(described_class.label_for(described_class::DECLINATION_LABELS, 0.85)).to eq(:severe)
    end
  end
end
