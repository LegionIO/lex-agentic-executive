# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Control::Helpers::ControlSignal do
  subject(:signal) { described_class.new }

  describe '#initialize' do
    it 'starts at default effort' do
      expect(signal.effort_level).to eq(0.5)
    end

    it 'starts in automatic mode' do
      expect(signal.mode).to eq(:automatic)
    end

    it 'has no detections' do
      expect(signal.conflict_detected).to be false
      expect(signal.error_detected).to be false
      expect(signal.novelty_detected).to be false
    end
  end

  describe '#detect_conflict' do
    it 'boosts effort and flags conflict' do
      original = signal.effort_level
      signal.detect_conflict
      expect(signal.effort_level).to be > original
      expect(signal.conflict_detected).to be true
    end
  end

  describe '#detect_error' do
    it 'boosts effort and flags error' do
      original = signal.effort_level
      signal.detect_error
      expect(signal.effort_level).to be > original
      expect(signal.error_detected).to be true
    end
  end

  describe '#detect_novelty' do
    it 'boosts effort and flags novelty' do
      original = signal.effort_level
      signal.detect_novelty
      expect(signal.effort_level).to be > original
      expect(signal.novelty_detected).to be true
    end
  end

  describe '#reset_detections' do
    it 'clears all detection flags' do
      signal.detect_conflict
      signal.detect_error
      signal.detect_novelty
      signal.reset_detections
      expect(signal.conflict_detected).to be false
      expect(signal.error_detected).to be false
      expect(signal.novelty_detected).to be false
    end
  end

  describe '#mode' do
    it 'returns :automatic when effort is low' do
      20.times { signal.decay }
      expect(signal.mode).to eq(:automatic)
    end

    it 'returns :controlled after a small boost' do
      signal.detect_novelty
      expect(signal.mode).to eq(:controlled)
    end

    it 'returns :override when effort is high' do
      signal.detect_conflict
      signal.detect_error
      expect(signal.mode).to eq(:override)
    end
  end

  describe '#effort_label' do
    it 'returns a symbol label' do
      expect(signal.effort_label).to be_a(Symbol)
    end
  end

  describe '#decay' do
    it 'reduces effort' do
      original = signal.effort_level
      signal.decay
      expect(signal.effort_level).to be < original
    end

    it 'does not go below floor' do
      50.times { signal.decay }
      expect(signal.effort_level).to be >= 0.1
    end
  end

  describe '#recover' do
    it 'increases effort' do
      signal.decay
      original = signal.effort_level
      signal.recover
      expect(signal.effort_level).to be > original
    end

    it 'does not exceed ceiling' do
      50.times { signal.recover }
      expect(signal.effort_level).to be <= 1.0
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      expect(signal.to_h).to include(:effort_level, :mode, :effort_label, :conflict_detected,
                                     :error_detected, :novelty_detected)
    end
  end
end
