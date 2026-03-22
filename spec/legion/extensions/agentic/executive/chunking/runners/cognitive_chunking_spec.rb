# frozen_string_literal: true

require 'legion/extensions/agentic/executive/chunking/client'

RSpec.describe Legion::Extensions::Agentic::Executive::Chunking::Runners::CognitiveChunking do
  let(:engine) { Legion::Extensions::Agentic::Executive::Chunking::Helpers::ChunkingEngine.new }
  let(:client) { Legion::Extensions::Agentic::Executive::Chunking::Client.new }

  def add_items_to(target_engine, count)
    count.times.map { |i| target_engine.add_item(content: "item #{i}")[:item_id] }
  end

  describe '#add_item' do
    it 'returns success' do
      result = client.add_item(content: 'knight fork', domain: :chess)
      expect(result[:success]).to be true
    end

    it 'accepts injected engine' do
      result = client.add_item(content: 'test', engine: engine)
      expect(result[:success]).to be true
      expect(engine.items.size).to eq(1)
    end

    it 'returns item_id' do
      result = client.add_item(content: 'fork threat')
      expect(result[:item_id]).to be_a(String)
    end
  end

  describe '#create_chunk' do
    let(:item_ids) { add_items_to(engine, 3) }

    it 'creates a chunk via injected engine' do
      result = client.create_chunk(label: 'chess tactics', item_ids: item_ids, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns chunk_id' do
      result = client.create_chunk(label: 'tactics', item_ids: item_ids, engine: engine)
      expect(result[:chunk_id]).to be_a(String)
    end

    it 'fails for empty item_ids' do
      result = client.create_chunk(label: 'empty', item_ids: [], engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#merge_chunks' do
    let(:item_ids_a) { add_items_to(engine, 2) }
    let(:item_ids_b) { add_items_to(engine, 2) }
    let(:chunk_a_id) { engine.create_chunk(label: 'A', item_ids: item_ids_a)[:chunk_id] }
    let(:chunk_b_id) { engine.create_chunk(label: 'B', item_ids: item_ids_b)[:chunk_id] }

    it 'merges two chunks' do
      result = client.merge_chunks(chunk_ids: [chunk_a_id, chunk_b_id], label: 'AB', engine: engine)
      expect(result[:success]).to be true
    end

    it 'marks parent as hierarchical' do
      result = client.merge_chunks(chunk_ids: [chunk_a_id, chunk_b_id], label: 'AB', engine: engine)
      parent = engine.chunks[result[:chunk_id]]
      expect(parent.hierarchical?).to be true
    end
  end

  describe '#load_to_working_memory' do
    let(:item_id) { engine.add_item(content: 'wm item')[:item_id] }
    let(:chunk_id) { engine.create_chunk(label: 'wm', item_ids: [item_id])[:chunk_id] }

    it 'loads chunk to working memory' do
      result = client.load_to_working_memory(chunk_id: chunk_id, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns working_memory_size' do
      result = client.load_to_working_memory(chunk_id: chunk_id, engine: engine)
      expect(result[:working_memory_size]).to eq(1)
    end
  end

  describe '#unload_from_working_memory' do
    let(:item_id) { engine.add_item(content: 'unload item')[:item_id] }
    let(:chunk_id) { engine.create_chunk(label: 'unload', item_ids: [item_id])[:chunk_id] }

    before { engine.load_to_working_memory(chunk_id: chunk_id) }

    it 'unloads chunk from working memory' do
      result = client.unload_from_working_memory(chunk_id: chunk_id, engine: engine)
      expect(result[:success]).to be true
      expect(engine.working_memory).not_to include(chunk_id)
    end
  end

  describe '#working_memory_status' do
    it 'returns success with capacity info' do
      result = client.working_memory_status(engine: engine)
      expect(result[:success]).to be true
      expect(result[:capacity]).to eq(4)
    end

    it 'returns a capacity label' do
      result = client.working_memory_status(engine: engine)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'reports not overloaded for empty working memory' do
      result = client.working_memory_status(engine: engine)
      expect(result[:overloaded]).to be false
    end
  end

  describe '#decay_all' do
    it 'returns success' do
      result = client.decay_all(engine: engine)
      expect(result[:success]).to be true
    end

    it 'decays chunks in the engine' do
      id = engine.add_item(content: 'decay me')[:item_id]
      cid = engine.create_chunk(label: 'decay', item_ids: [id])[:chunk_id]
      before_recall = engine.chunks[cid].recall_strength
      client.decay_all(engine: engine)
      expect(engine.chunks[cid].recall_strength).to be < before_recall
    end
  end

  describe '#reinforce_chunk' do
    let(:item_id) { engine.add_item(content: 'reinforce')[:item_id] }
    let(:chunk_id) { engine.create_chunk(label: 'r', item_ids: [item_id])[:chunk_id] }

    it 'returns success' do
      result = client.reinforce_chunk(chunk_id: chunk_id, engine: engine)
      expect(result[:success]).to be true
    end

    it 'boosts the chunk recall' do
      before_recall = engine.chunks[chunk_id].recall_strength
      client.reinforce_chunk(chunk_id: chunk_id, engine: engine)
      expect(engine.chunks[chunk_id].recall_strength).to be > before_recall
    end
  end

  describe '#chunking_report' do
    it 'returns success with report' do
      result = client.chunking_report(engine: engine)
      expect(result[:success]).to be true
      expect(result[:report]).to have_key(:total_items)
    end
  end

  describe '#strongest_chunks' do
    it 'returns success with chunks array' do
      result = client.strongest_chunks(engine: engine)
      expect(result[:success]).to be true
      expect(result[:chunks]).to be_an(Array)
    end
  end

  describe '#unchunked_items' do
    it 'returns success with items array' do
      engine.add_item(content: 'free item')
      result = client.unchunked_items(engine: engine)
      expect(result[:success]).to be true
      expect(result[:items].size).to eq(1)
    end
  end
end
