# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Chunking::Helpers::Chunk do
  let(:chunk) { described_class.new(label: 'chess opening') }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(chunk.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores label' do
      expect(chunk.label).to eq('chess opening')
    end

    it 'starts with empty item_ids' do
      expect(chunk.item_ids).to be_empty
    end

    it 'starts with empty sub_chunk_ids' do
      expect(chunk.sub_chunk_ids).to be_empty
    end

    it 'starts with DEFAULT_COHERENCE' do
      expect(chunk.coherence).to eq(Legion::Extensions::Agentic::Executive::Chunking::Helpers::Constants::DEFAULT_COHERENCE)
    end

    it 'starts with recall_strength of 0.8' do
      expect(chunk.recall_strength).to eq(0.8)
    end

    it 'starts with access_count of 0' do
      expect(chunk.access_count).to eq(0)
    end

    it 'pre-populates item_ids from constructor' do
      c = described_class.new(label: 'test', item_ids: %w[a b c])
      expect(c.item_ids).to eq(%w[a b c])
    end

    it 'does not share item_ids reference' do
      ids = %w[a b]
      c = described_class.new(label: 'test', item_ids: ids)
      ids << 'c'
      expect(c.item_ids.size).to eq(2)
    end
  end

  describe '#add_item!' do
    it 'adds item_id to item_ids' do
      chunk.add_item!(item_id: 'abc')
      expect(chunk.item_ids).to include('abc')
    end

    it 'does not add duplicates' do
      chunk.add_item!(item_id: 'abc')
      chunk.add_item!(item_id: 'abc')
      expect(chunk.item_ids.count('abc')).to eq(1)
    end
  end

  describe '#remove_item!' do
    before { chunk.add_item!(item_id: 'abc') }

    it 'removes item_id' do
      chunk.remove_item!(item_id: 'abc')
      expect(chunk.item_ids).not_to include('abc')
    end
  end

  describe '#add_sub_chunk!' do
    it 'adds sub_chunk_id' do
      chunk.add_sub_chunk!(chunk_id: 'sub-1')
      expect(chunk.sub_chunk_ids).to include('sub-1')
    end

    it 'does not add duplicates' do
      chunk.add_sub_chunk!(chunk_id: 'sub-1')
      chunk.add_sub_chunk!(chunk_id: 'sub-1')
      expect(chunk.sub_chunk_ids.count('sub-1')).to eq(1)
    end
  end

  describe '#reinforce!' do
    it 'increments access_count' do
      chunk.reinforce!
      expect(chunk.access_count).to eq(1)
    end

    it 'boosts coherence' do
      original = chunk.coherence
      chunk.reinforce!
      expect(chunk.coherence).to be > original
    end

    it 'boosts recall_strength' do
      original = chunk.recall_strength
      chunk.reinforce!
      expect(chunk.recall_strength).to be > original
    end

    it 'caps coherence at 1.0' do
      20.times { chunk.reinforce! }
      expect(chunk.coherence).to eq(1.0)
    end

    it 'caps recall_strength at 1.0' do
      20.times { chunk.reinforce! }
      expect(chunk.recall_strength).to eq(1.0)
    end
  end

  describe '#decay!' do
    it 'reduces recall_strength' do
      original = chunk.recall_strength
      chunk.decay!
      expect(chunk.recall_strength).to be < original
    end

    it 'reduces coherence' do
      original = chunk.coherence
      chunk.decay!
      expect(chunk.coherence).to be < original
    end

    it 'floors recall_strength at 0.0' do
      100.times { chunk.decay! }
      expect(chunk.recall_strength).to eq(0.0)
    end
  end

  describe '#size' do
    it 'returns count of item_ids' do
      chunk.add_item!(item_id: 'a')
      chunk.add_item!(item_id: 'b')
      expect(chunk.size).to eq(2)
    end
  end

  describe '#hierarchical?' do
    it 'returns false when no sub_chunks' do
      expect(chunk.hierarchical?).to be false
    end

    it 'returns true when sub_chunks exist' do
      chunk.add_sub_chunk!(chunk_id: 'child')
      expect(chunk.hierarchical?).to be true
    end
  end

  describe '#coherence_label' do
    it 'returns :loosely_chunked for default coherence (0.5)' do
      expect(chunk.coherence_label).to eq(:loosely_chunked)
    end
  end

  describe '#recall_label' do
    it 'returns :instant for high recall_strength (0.8)' do
      expect(chunk.recall_label).to eq(:instant)
    end
  end

  describe '#size_label' do
    it 'returns :micro for empty chunk' do
      expect(chunk.size_label).to eq(:micro)
    end

    it 'returns :large for 7+ items' do
      7.times { |i| chunk.add_item!(item_id: "item-#{i}") }
      expect(chunk.size_label).to eq(:large)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = chunk.to_h
      expected = %i[id label item_ids sub_chunk_ids coherence recall_strength
                    access_count created_at size hierarchical coherence_label
                    recall_label size_label]
      expect(h.keys).to include(*expected)
    end

    it 'rounds coherence to 10 decimal places' do
      chunk.reinforce!
      expect(chunk.to_h[:coherence]).to eq(chunk.coherence.round(10))
    end
  end
end
