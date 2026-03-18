# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Compass::Helpers::CompassEngine do
  subject(:engine) { described_class.new }

  describe '#take_bearing' do
    it 'creates a bearing' do
      b = engine.take_bearing(direction: :north, context: 'truth seeking')
      expect(b).to be_a(Legion::Extensions::Agentic::Executive::Compass::Helpers::Bearing)
    end
  end

  describe '#register_bias' do
    it 'creates a magnetic bias' do
      b = engine.register_bias(bias_type: :confirmation, domain: :reasoning)
      expect(b).to be_a(Legion::Extensions::Agentic::Executive::Compass::Helpers::MagneticBias)
    end

    it 'raises when too many biases' do
      stub_const('Legion::Extensions::Agentic::Executive::Compass::Helpers::Constants::MAX_BIASES', 1)
      engine.register_bias(bias_type: :confirmation, domain: :x)
      expect { engine.register_bias(bias_type: :anchoring, domain: :y) }
        .to raise_error(ArgumentError, /too many biases/)
    end
  end

  describe '#calibrate' do
    it 'reduces bias declination' do
      bias = engine.register_bias(bias_type: :anchoring, domain: :x, declination: 0.5)
      engine.calibrate(bias_id: bias.id)
      expect(bias.declination).to be < 0.5
    end

    it 'raises for unknown bias' do
      expect { engine.calibrate(bias_id: 'nope') }
        .to raise_error(ArgumentError, /bias not found/)
    end
  end

  describe '#true_north_offset' do
    it 'returns 0.0 with no biases' do
      expect(engine.true_north_offset).to eq(0.0)
    end

    it 'returns average declination' do
      engine.register_bias(bias_type: :confirmation, domain: :x, declination: 0.4)
      engine.register_bias(bias_type: :anchoring, domain: :y, declination: 0.6)
      expect(engine.true_north_offset).to eq(0.5)
    end
  end

  describe '#accuracy' do
    it 'returns 1.0 with no biases' do
      expect(engine.accuracy).to eq(1.0)
    end

    it 'decreases with biases' do
      engine.register_bias(bias_type: :confirmation, domain: :x, declination: 0.5)
      expect(engine.accuracy).to be < 1.0
    end
  end

  describe '#decay_biases!' do
    it 'decays all biases' do
      bias = engine.register_bias(bias_type: :recency, domain: :x, strength: 0.5)
      old = bias.strength
      engine.decay_biases!
      expect(bias.strength).to be < old
    end
  end

  describe '#dominant_direction' do
    it 'returns nil with no bearings' do
      expect(engine.dominant_direction).to be_nil
    end

    it 'returns the most common direction weighted by confidence' do
      engine.take_bearing(direction: :north, context: 'a', confidence: 0.9)
      engine.take_bearing(direction: :south, context: 'b', confidence: 0.3)
      expect(engine.dominant_direction).to eq(:north)
    end
  end

  describe '#bearings_by_direction' do
    it 'counts bearings per direction' do
      engine.take_bearing(direction: :north, context: 'a')
      engine.take_bearing(direction: :north, context: 'b')
      engine.take_bearing(direction: :east, context: 'c')
      result = engine.bearings_by_direction
      expect(result[:north]).to eq(2)
      expect(result[:east]).to eq(1)
    end
  end

  describe '#strongest_biases' do
    it 'returns biases sorted by strength' do
      engine.register_bias(bias_type: :confirmation, domain: :x, strength: 0.3)
      strong = engine.register_bias(bias_type: :anchoring, domain: :y, strength: 0.9)
      expect(engine.strongest_biases(limit: 1).first).to eq(strong)
    end
  end

  describe '#compass_report' do
    it 'returns comprehensive report' do
      engine.take_bearing(direction: :north, context: 'test')
      report = engine.compass_report
      %i[total_bearings total_biases accuracy accuracy_label
         true_north_offset dominant_direction by_direction severe_biases].each do |k|
        expect(report).to have_key(k)
      end
    end
  end
end
