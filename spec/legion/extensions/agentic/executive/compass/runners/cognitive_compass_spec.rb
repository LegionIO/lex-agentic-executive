# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Compass::Runners::CognitiveCompass do
  let(:engine) { Legion::Extensions::Agentic::Executive::Compass::Helpers::CompassEngine.new }

  describe '.take_bearing' do
    it 'returns success' do
      result = described_class.take_bearing(
        direction: :north, context: 'truth seeking', engine: engine
      )
      expect(result[:success]).to be true
      expect(result[:bearing][:direction]).to eq(:north)
    end

    it 'returns failure for invalid direction' do
      result = described_class.take_bearing(
        direction: :up, context: 'x', engine: engine
      )
      expect(result[:success]).to be false
    end
  end

  describe '.register_bias' do
    it 'returns success' do
      result = described_class.register_bias(
        bias_type: :confirmation, domain: :reasoning, engine: engine
      )
      expect(result[:success]).to be true
      expect(result[:bias][:bias_type]).to eq(:confirmation)
    end

    it 'returns failure for invalid bias' do
      result = described_class.register_bias(
        bias_type: :laziness, domain: :x, engine: engine
      )
      expect(result[:success]).to be false
    end
  end

  describe '.calibrate' do
    it 'reduces declination' do
      bias = engine.register_bias(bias_type: :anchoring, domain: :x, declination: 0.5)
      result = described_class.calibrate(bias_id: bias.id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:bias][:declination]).to be < 0.5
    end
  end

  describe '.list_bearings' do
    it 'returns all bearings' do
      engine.take_bearing(direction: :north, context: 'a')
      engine.take_bearing(direction: :east, context: 'b')
      result = described_class.list_bearings(engine: engine)
      expect(result[:count]).to eq(2)
    end

    it 'filters by direction' do
      engine.take_bearing(direction: :north, context: 'a')
      engine.take_bearing(direction: :east, context: 'b')
      result = described_class.list_bearings(engine: engine, direction: :north)
      expect(result[:count]).to eq(1)
    end
  end

  describe '.list_biases' do
    it 'returns all biases' do
      engine.register_bias(bias_type: :recency, domain: :x)
      result = described_class.list_biases(engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '.compass_status' do
    it 'returns report' do
      result = described_class.compass_status(engine: engine)
      expect(result[:success]).to be true
      expect(result[:report]).to have_key(:accuracy)
    end
  end
end
