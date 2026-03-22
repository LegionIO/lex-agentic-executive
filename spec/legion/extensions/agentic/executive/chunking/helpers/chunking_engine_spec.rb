# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Chunking::Helpers::ChunkingEngine do
  let(:engine) { described_class.new }

  def add_items(count, domain: :general)
    count.times.map { |i| engine.add_item(content: "item #{i}", domain: domain) }
  end

  describe '#add_item' do
    it 'returns success with item_id' do
      result = engine.add_item(content: 'rook pins queen', domain: :chess)
      expect(result[:success]).to be true
      expect(result[:item_id]).to be_a(String)
    end

    it 'stores the item' do
      result = engine.add_item(content: 'test', domain: :general)
      expect(engine.items[result[:item_id]]).not_to be_nil
    end

    it 'returns item hash in result' do
      result = engine.add_item(content: 'test')
      expect(result[:item]).to have_key(:id)
    end
  end

  describe '#create_chunk' do
    let(:items) { add_items(3) }
    let(:item_ids) { items.map { |r| r[:item_id] } }

    it 'returns success with chunk_id' do
      result = engine.create_chunk(label: 'group', item_ids: item_ids)
      expect(result[:success]).to be true
      expect(result[:chunk_id]).to be_a(String)
    end

    it 'stores the chunk' do
      result = engine.create_chunk(label: 'group', item_ids: item_ids)
      expect(engine.chunks[result[:chunk_id]]).not_to be_nil
    end

    it 'marks items as chunked' do
      result = engine.create_chunk(label: 'group', item_ids: item_ids)
      item_ids.each do |id|
        expect(engine.items[id].chunked?).to be true
        expect(engine.items[id].chunk_id).to eq(result[:chunk_id])
      end
    end

    it 'fails for empty item_ids' do
      result = engine.create_chunk(label: 'empty', item_ids: [])
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:empty_item_ids)
    end

    it 'fails for non-existent item_ids' do
      result = engine.create_chunk(label: 'bad', item_ids: %w[nonexistent])
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:no_valid_items)
    end
  end

  describe '#merge_chunks' do
    def setup_two_chunks
      items_a = add_items(2)
      items_b = add_items(2)
      chunk_a = engine.create_chunk(label: 'A', item_ids: items_a.map { |r| r[:item_id] })
      chunk_b = engine.create_chunk(label: 'B', item_ids: items_b.map { |r| r[:item_id] })
      [chunk_a[:chunk_id], chunk_b[:chunk_id]]
    end

    it 'creates a hierarchical parent chunk' do
      chunk_ids = setup_two_chunks
      result = engine.merge_chunks(chunk_ids: chunk_ids, label: 'Parent')
      expect(result[:success]).to be true
      parent = engine.chunks[result[:chunk_id]]
      expect(parent.hierarchical?).to be true
    end

    it 'parent has all item_ids from children' do
      chunk_ids = setup_two_chunks
      result = engine.merge_chunks(chunk_ids: chunk_ids, label: 'Parent')
      parent = engine.chunks[result[:chunk_id]]
      expect(parent.item_ids.size).to eq(4)
    end

    it 'includes merged_from in result' do
      chunk_ids = setup_two_chunks
      result = engine.merge_chunks(chunk_ids: chunk_ids, label: 'Parent')
      expect(result[:merged_from]).to match_array(chunk_ids)
    end

    it 'fails with fewer than 2 chunk_ids' do
      add_items(2)
      result = engine.merge_chunks(chunk_ids: ['only-one'], label: 'Bad')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:insufficient_chunks)
    end
  end

  describe '#load_to_working_memory' do
    let(:item_id) { engine.add_item(content: 'test')[:item_id] }
    let(:chunk_id) { engine.create_chunk(label: 'wm test', item_ids: [item_id])[:chunk_id] }

    it 'adds chunk to working memory' do
      result = engine.load_to_working_memory(chunk_id: chunk_id)
      expect(result[:success]).to be true
      expect(engine.working_memory).to include(chunk_id)
    end

    it 'reinforces the chunk on load' do
      original_count = engine.chunks[chunk_id].access_count
      engine.load_to_working_memory(chunk_id: chunk_id)
      expect(engine.chunks[chunk_id].access_count).to be > original_count
    end

    it 'fails for unknown chunk' do
      result = engine.load_to_working_memory(chunk_id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:chunk_not_found)
    end

    it 'fails when already loaded' do
      engine.load_to_working_memory(chunk_id: chunk_id)
      result = engine.load_to_working_memory(chunk_id: chunk_id)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:already_loaded)
    end

    it 'fails when working memory is at capacity' do
      # Fill working memory to WORKING_MEMORY_CAPACITY
      7.times do
        id = engine.add_item(content: 'filler')[:item_id]
        cid = engine.create_chunk(label: 'filler', item_ids: [id])[:chunk_id]
        engine.load_to_working_memory(chunk_id: cid)
      end
      result = engine.load_to_working_memory(chunk_id: chunk_id)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:capacity_exceeded)
    end
  end

  describe '#unload_from_working_memory' do
    let(:item_id) { engine.add_item(content: 'test')[:item_id] }
    let(:chunk_id) { engine.create_chunk(label: 'unload test', item_ids: [item_id])[:chunk_id] }

    before { engine.load_to_working_memory(chunk_id: chunk_id) }

    it 'removes chunk from working memory' do
      engine.unload_from_working_memory(chunk_id: chunk_id)
      expect(engine.working_memory).not_to include(chunk_id)
    end

    it 'returns success' do
      result = engine.unload_from_working_memory(chunk_id: chunk_id)
      expect(result[:success]).to be true
    end

    it 'fails if not in working memory' do
      engine.unload_from_working_memory(chunk_id: chunk_id)
      result = engine.unload_from_working_memory(chunk_id: chunk_id)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_in_working_memory)
    end
  end

  describe '#working_memory_load' do
    it 'returns 0.0 for empty working memory' do
      expect(engine.working_memory_load).to eq(0.0)
    end

    it 'returns load as a ratio' do
      id = engine.add_item(content: 'x')[:item_id]
      cid = engine.create_chunk(label: 'x', item_ids: [id])[:chunk_id]
      engine.load_to_working_memory(chunk_id: cid)
      expected = (1.0 / 4).round(10)
      expect(engine.working_memory_load).to be_within(0.0001).of(expected)
    end
  end

  describe '#working_memory_overloaded?' do
    it 'returns false when under capacity' do
      expect(engine.working_memory_overloaded?).to be false
    end
  end

  describe '#decay_all!' do
    it 'decays all chunks' do
      id = engine.add_item(content: 'x')[:item_id]
      cid = engine.create_chunk(label: 'x', item_ids: [id])[:chunk_id]
      original_recall = engine.chunks[cid].recall_strength
      engine.decay_all!
      expect(engine.chunks[cid].recall_strength).to be < original_recall
    end

    it 'returns success with count' do
      add_items(3).each_with_index do |r, i|
        engine.create_chunk(label: "c#{i}", item_ids: [r[:item_id]])
      end
      result = engine.decay_all!
      expect(result[:success]).to be true
      expect(result[:chunks_decayed]).to eq(3)
    end
  end

  describe '#reinforce_chunk' do
    let(:item_id) { engine.add_item(content: 'reinforce me')[:item_id] }
    let(:chunk_id) { engine.create_chunk(label: 'reinforce', item_ids: [item_id])[:chunk_id] }

    it 'boosts recall strength' do
      before_recall = engine.chunks[chunk_id].recall_strength
      engine.reinforce_chunk(chunk_id: chunk_id)
      expect(engine.chunks[chunk_id].recall_strength).to be > before_recall
    end

    it 'fails for unknown chunk_id' do
      result = engine.reinforce_chunk(chunk_id: 'bad')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:chunk_not_found)
    end
  end

  describe '#strongest_chunks' do
    it 'returns chunks sorted by recall_strength descending' do
      r1 = engine.add_item(content: 'a')[:item_id]
      r2 = engine.add_item(content: 'b')[:item_id]
      c1 = engine.create_chunk(label: 'weak', item_ids: [r1])[:chunk_id]
      c2 = engine.create_chunk(label: 'strong', item_ids: [r2])[:chunk_id]
      engine.chunks[c1].decay!
      engine.chunks[c2].reinforce!
      chunks = engine.strongest_chunks(limit: 2)
      expect(chunks.first[:recall_strength]).to be >= chunks.last[:recall_strength]
    end

    it 'respects limit' do
      add_items(5).each_with_index { |r, i| engine.create_chunk(label: "c#{i}", item_ids: [r[:item_id]]) }
      expect(engine.strongest_chunks(limit: 3).size).to eq(3)
    end
  end

  describe '#unchunked_items' do
    it 'returns items not in any chunk' do
      r1 = engine.add_item(content: 'chunked item')[:item_id]
      engine.add_item(content: 'free item')
      engine.create_chunk(label: 'group', item_ids: [r1])
      unchunked = engine.unchunked_items
      expect(unchunked.size).to eq(1)
      expect(unchunked.first[:content]).to eq('free item')
    end
  end

  describe '#chunking_efficiency' do
    it 'returns 0.0 for no items' do
      expect(engine.chunking_efficiency).to eq(0.0)
    end

    it 'returns ratio of chunked to total' do
      r1 = engine.add_item(content: 'a')[:item_id]
      engine.add_item(content: 'b')
      engine.create_chunk(label: 'test', item_ids: [r1])
      expect(engine.chunking_efficiency).to be_within(0.001).of(0.5)
    end
  end

  describe '#chunking_report' do
    it 'includes required report keys' do
      report = engine.chunking_report
      expect(report).to have_key(:total_items)
      expect(report).to have_key(:total_chunks)
      expect(report).to have_key(:unchunked_items)
      expect(report).to have_key(:chunking_efficiency)
      expect(report).to have_key(:working_memory)
      expect(report).to have_key(:strongest_chunks)
    end

    it 'includes working memory capacity label' do
      expect(engine.chunking_report[:working_memory][:label]).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'includes items, chunks, and working_memory keys' do
      h = engine.to_h
      expect(h).to have_key(:items)
      expect(h).to have_key(:chunks)
      expect(h).to have_key(:working_memory)
    end
  end
end
