# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Compass::Helpers::MagneticBias do
  subject(:bias) do
    described_class.new(bias_type: :confirmation, domain: :reasoning)
  end

  describe '#initialize' do
    it 'sets bias type' do
      expect(bias.bias_type).to eq(:confirmation)
    end

    it 'sets domain' do
      expect(bias.domain).to eq(:reasoning)
    end

    it 'defaults declination to 0.3' do
      expect(bias.declination).to eq(0.3)
    end

    it 'defaults strength to 0.5' do
      expect(bias.strength).to eq(0.5)
    end

    it 'rejects unknown bias types' do
      expect { described_class.new(bias_type: :laziness, domain: :x) }
        .to raise_error(ArgumentError, /unknown bias type/)
    end
  end

  describe '#correct!' do
    it 'reduces declination' do
      old = bias.declination
      bias.correct!
      expect(bias.declination).to be < old
    end

    it 'does not go below zero' do
      10.times { bias.correct!(amount: 0.5) }
      expect(bias.declination).to eq(0.0)
    end
  end

  describe '#intensify!' do
    it 'increases strength' do
      old = bias.strength
      bias.intensify!
      expect(bias.strength).to be > old
    end

    it 'increases declination' do
      old = bias.declination
      bias.intensify!
      expect(bias.declination).to be > old
    end
  end

  describe '#decay!' do
    it 'reduces strength' do
      old = bias.strength
      bias.decay!
      expect(bias.strength).to be < old
    end
  end

  describe '#severe?' do
    it 'returns false at default declination' do
      expect(bias.severe?).to be false
    end

    it 'returns true at high declination' do
      b = described_class.new(bias_type: :anchoring, domain: :x, declination: 0.9)
      expect(b.severe?).to be true
    end
  end

  describe '#negligible?' do
    it 'returns false at default declination' do
      expect(bias.negligible?).to be false
    end

    it 'returns true after correction' do
      5.times { bias.correct!(amount: 0.1) }
      expect(bias.negligible?).to be true
    end
  end

  describe '#declination_label' do
    it 'returns a symbol' do
      expect(bias.declination_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'returns all keys' do
      h = bias.to_h
      %i[id bias_type domain declination declination_label
         strength severe negligible detected_at].each do |k|
        expect(h).to have_key(k)
      end
    end
  end
end
