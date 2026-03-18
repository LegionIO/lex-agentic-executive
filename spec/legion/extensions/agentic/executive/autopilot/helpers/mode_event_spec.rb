# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Autopilot::Helpers::ModeEvent do
  describe '#override?' do
    it 'is true for autopilot to deliberate' do
      event = described_class.new(from_mode: :autopilot, to_mode: :deliberate, trigger: 'novel_task')
      expect(event.override?).to be true
    end

    it 'is false for deliberate to autopilot' do
      event = described_class.new(from_mode: :deliberate, to_mode: :autopilot, trigger: 'familiar')
      expect(event.override?).to be false
    end
  end

  describe '#engage_autopilot?' do
    it 'is true for deliberate to autopilot' do
      event = described_class.new(from_mode: :deliberate, to_mode: :autopilot, trigger: 'routine')
      expect(event.engage_autopilot?).to be true
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      event = described_class.new(from_mode: :autopilot, to_mode: :deliberate, trigger: 'test')
      hash = event.to_h
      expect(hash).to include(:id, :from_mode, :to_mode, :trigger, :energy_cost, :override)
    end
  end
end
