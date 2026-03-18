# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::Constants do
  describe 'MAX_INTENTIONS' do
    it 'is 300' do
      expect(described_class::MAX_INTENTIONS).to eq(300)
    end
  end

  describe 'DEFAULT_URGENCY' do
    it 'is 0.5' do
      expect(described_class::DEFAULT_URGENCY).to eq(0.5)
    end
  end

  describe 'URGENCY_DECAY' do
    it 'is 0.01' do
      expect(described_class::URGENCY_DECAY).to eq(0.01)
    end
  end

  describe 'URGENCY_BOOST' do
    it 'is 0.1' do
      expect(described_class::URGENCY_BOOST).to eq(0.1)
    end
  end

  describe 'CHECK_INTERVAL' do
    it 'is 60' do
      expect(described_class::CHECK_INTERVAL).to eq(60)
    end
  end

  describe 'URGENCY_LABELS' do
    it 'maps 0.9 to :critical' do
      label = described_class::URGENCY_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:critical)
    end

    it 'maps 0.7 to :high' do
      label = described_class::URGENCY_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:high)
    end

    it 'maps 0.5 to :moderate' do
      label = described_class::URGENCY_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:moderate)
    end

    it 'maps 0.3 to :low' do
      label = described_class::URGENCY_LABELS.find { |range, _| range.cover?(0.3) }&.last
      expect(label).to eq(:low)
    end

    it 'maps 0.1 to :deferred' do
      label = described_class::URGENCY_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:deferred)
    end

    it 'is frozen' do
      expect(described_class::URGENCY_LABELS).to be_frozen
    end
  end

  describe 'STATUS_TYPES' do
    it 'includes all expected statuses' do
      expect(described_class::STATUS_TYPES).to include(:pending, :monitoring, :triggered, :executed, :expired, :cancelled)
    end

    it 'is frozen' do
      expect(described_class::STATUS_TYPES).to be_frozen
    end
  end

  describe 'TRIGGER_TYPES' do
    it 'includes all expected trigger types' do
      expect(described_class::TRIGGER_TYPES).to include(:time_based, :event_based, :context_based, :activity_based)
    end

    it 'is frozen' do
      expect(described_class::TRIGGER_TYPES).to be_frozen
    end
  end
end
