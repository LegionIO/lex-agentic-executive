# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Chunking::Helpers::Constants do
  describe 'core capacity constants' do
    it 'defines MAX_ITEMS as 500' do
      expect(described_class::MAX_ITEMS).to eq(500)
    end

    it 'defines MAX_CHUNKS as 200' do
      expect(described_class::MAX_CHUNKS).to eq(200)
    end

    it 'defines WORKING_MEMORY_CAPACITY as 7' do
      expect(described_class::WORKING_MEMORY_CAPACITY).to eq(7)
    end

    it 'defines CAPACITY_VARIANCE as 2' do
      expect(described_class::CAPACITY_VARIANCE).to eq(2)
    end
  end

  describe 'score constants' do
    it 'defines DEFAULT_COHERENCE as 0.5' do
      expect(described_class::DEFAULT_COHERENCE).to eq(0.5)
    end

    it 'defines COHERENCE_BOOST as 0.08' do
      expect(described_class::COHERENCE_BOOST).to eq(0.08)
    end

    it 'defines COHERENCE_DECAY as 0.03' do
      expect(described_class::COHERENCE_DECAY).to eq(0.03)
    end

    it 'defines RECALL_DECAY as 0.02' do
      expect(described_class::RECALL_DECAY).to eq(0.02)
    end

    it 'defines RECALL_BOOST as 0.1' do
      expect(described_class::RECALL_BOOST).to eq(0.1)
    end
  end

  describe 'CHUNK_SIZE_LABELS' do
    it 'labels size 7 as large' do
      label = described_class::CHUNK_SIZE_LABELS.find { |range, _| range.cover?(7) }&.last
      expect(label).to eq(:large)
    end

    it 'labels size 5 as medium' do
      label = described_class::CHUNK_SIZE_LABELS.find { |range, _| range.cover?(5) }&.last
      expect(label).to eq(:medium)
    end

    it 'labels size 3 as small' do
      label = described_class::CHUNK_SIZE_LABELS.find { |range, _| range.cover?(3) }&.last
      expect(label).to eq(:small)
    end

    it 'labels size 1 as micro' do
      label = described_class::CHUNK_SIZE_LABELS.find { |range, _| range.cover?(1) }&.last
      expect(label).to eq(:micro)
    end
  end

  describe 'COHERENCE_LABELS' do
    it 'labels 0.9 as tightly_chunked' do
      label = described_class::COHERENCE_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:tightly_chunked)
    end

    it 'labels 0.5 as loosely_chunked' do
      label = described_class::COHERENCE_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:loosely_chunked)
    end

    it 'labels 0.1 as unchunked' do
      label = described_class::COHERENCE_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:unchunked)
    end
  end

  describe 'RECALL_LABELS' do
    it 'labels 0.9 as instant' do
      label = described_class::RECALL_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:instant)
    end

    it 'labels 0.5 as moderate' do
      label = described_class::RECALL_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:moderate)
    end

    it 'labels 0.1 as forgotten' do
      label = described_class::RECALL_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:forgotten)
    end
  end

  describe 'CAPACITY_LABELS' do
    it 'labels 0.9 as overloaded' do
      label = described_class::CAPACITY_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:overloaded)
    end

    it 'labels 0.5 as comfortable' do
      label = described_class::CAPACITY_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:comfortable)
    end

    it 'labels 0.1 as empty' do
      label = described_class::CAPACITY_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:empty)
    end
  end
end
