# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Compass::Helpers::Bearing do
  subject(:bearing) do
    described_class.new(direction: :north, context: 'seeking truth')
  end

  describe '#initialize' do
    it 'sets direction' do
      expect(bearing.direction).to eq(:north)
    end

    it 'resolves value axis' do
      expect(bearing.value_axis).to eq(:truth)
    end

    it 'sets context' do
      expect(bearing.context).to eq('seeking truth')
    end

    it 'generates uuid' do
      expect(bearing.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'defaults confidence to 0.7' do
      expect(bearing.confidence).to eq(0.7)
    end

    it 'accepts intercardinal directions' do
      b = described_class.new(direction: :northeast, context: 'pragmatic truth')
      expect(b.value_axis).to eq(%i[truth utility])
    end

    it 'rejects unknown directions' do
      expect { described_class.new(direction: :up, context: 'x') }
        .to raise_error(ArgumentError, /unknown direction/)
    end

    it 'accepts custom confidence' do
      b = described_class.new(direction: :south, context: 'x', confidence: 0.95)
      expect(b.confidence).to eq(0.95)
    end
  end

  describe '#reliable?' do
    it 'returns true at default confidence' do
      expect(bearing.reliable?).to be true
    end

    it 'returns false at low confidence' do
      b = described_class.new(direction: :east, context: 'x', confidence: 0.3)
      expect(b.reliable?).to be false
    end
  end

  describe '#lost?' do
    it 'returns false at default confidence' do
      expect(bearing.lost?).to be false
    end

    it 'returns true at very low confidence' do
      b = described_class.new(direction: :west, context: 'x', confidence: 0.1)
      expect(b.lost?).to be true
    end
  end

  describe '#cardinal?' do
    it 'returns true for cardinal directions' do
      expect(bearing.cardinal?).to be true
    end

    it 'returns false for intercardinal' do
      b = described_class.new(direction: :northeast, context: 'x')
      expect(b.cardinal?).to be false
    end
  end

  describe '#accuracy_label' do
    it 'returns a symbol' do
      expect(bearing.accuracy_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'returns all keys' do
      h = bearing.to_h
      %i[id direction value_axis context confidence accuracy_label
         cardinal reliable lost taken_at].each do |k|
        expect(h).to have_key(k)
      end
    end
  end
end
