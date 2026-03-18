# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::Constants do
  describe 'numeric constants' do
    it 'MAX_GOALS is 500' do
      expect(described_class::MAX_GOALS).to eq(500)
    end

    it 'MAX_DEPTH is 10' do
      expect(described_class::MAX_DEPTH).to eq(10)
    end

    it 'DEFAULT_PRIORITY is 0.5' do
      expect(described_class::DEFAULT_PRIORITY).to eq(0.5)
    end

    it 'PRIORITY_BOOST is 0.1' do
      expect(described_class::PRIORITY_BOOST).to eq(0.1)
    end

    it 'PRIORITY_DECAY is 0.02' do
      expect(described_class::PRIORITY_DECAY).to eq(0.02)
    end

    it 'PROGRESS_THRESHOLD is 0.9' do
      expect(described_class::PROGRESS_THRESHOLD).to eq(0.9)
    end

    it 'CONFLICT_THRESHOLD is 0.6' do
      expect(described_class::CONFLICT_THRESHOLD).to eq(0.6)
    end
  end

  describe 'GOAL_STATUSES' do
    it 'includes all lifecycle states' do
      expect(described_class::GOAL_STATUSES).to eq(%i[proposed active blocked completed abandoned])
    end

    it 'is frozen' do
      expect(described_class::GOAL_STATUSES).to be_frozen
    end
  end

  describe 'PRIORITY_LABELS' do
    it 'labels critical for high priority' do
      label = described_class::PRIORITY_LABELS.find { |l| l[:range].cover?(0.9) }&.fetch(:label)
      expect(label).to eq(:critical)
    end

    it 'labels trivial for low priority' do
      label = described_class::PRIORITY_LABELS.find { |l| l[:range].cover?(0.05) }&.fetch(:label)
      expect(label).to eq(:trivial)
    end

    it 'labels high for 0.7' do
      label = described_class::PRIORITY_LABELS.find { |l| l[:range].cover?(0.7) }&.fetch(:label)
      expect(label).to eq(:high)
    end

    it 'labels moderate for 0.5' do
      label = described_class::PRIORITY_LABELS.find { |l| l[:range].cover?(0.5) }&.fetch(:label)
      expect(label).to eq(:moderate)
    end
  end

  describe 'PROGRESS_LABELS' do
    it 'labels complete at 0.95' do
      label = described_class::PROGRESS_LABELS.find { |l| l[:range].cover?(0.95) }&.fetch(:label)
      expect(label).to eq(:complete)
    end

    it 'labels not_started at 0.0' do
      label = described_class::PROGRESS_LABELS.find { |l| l[:range].cover?(0.0) }&.fetch(:label)
      expect(label).to eq(:not_started)
    end

    it 'labels in_progress at 0.5' do
      label = described_class::PROGRESS_LABELS.find { |l| l[:range].cover?(0.5) }&.fetch(:label)
      expect(label).to eq(:in_progress)
    end
  end

  describe 'CONFLICT_LABELS' do
    it 'labels severe at 0.9' do
      label = described_class::CONFLICT_LABELS.find { |l| l[:range].cover?(0.9) }&.fetch(:label)
      expect(label).to eq(:severe)
    end

    it 'labels none at 0.05' do
      label = described_class::CONFLICT_LABELS.find { |l| l[:range].cover?(0.05) }&.fetch(:label)
      expect(label).to eq(:none)
    end
  end
end
