# frozen_string_literal: true

require 'legion/extensions/agentic/executive/chunking/client'

RSpec.describe Legion::Extensions::Agentic::Executive::Chunking::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    %i[add_item create_chunk merge_chunks load_to_working_memory
       unload_from_working_memory working_memory_status decay_all
       reinforce_chunk chunking_report strongest_chunks unchunked_items].each do |method|
      expect(client).to respond_to(method)
    end
  end

  it 'maintains state across calls using internal engine' do
    client.add_item(content: 'pawn structure')
    client.add_item(content: 'knight outpost')
    report = client.chunking_report
    expect(report[:report][:total_items]).to eq(2)
  end

  it 'runs a full chunking workflow' do
    r1 = client.add_item(content: 'e4 e5', domain: :chess)
    r2 = client.add_item(content: 'Nf3 Nc6', domain: :chess)
    r3 = client.add_item(content: 'Bb5', domain: :chess)

    chunk = client.create_chunk(
      label:    'Ruy Lopez opening',
      item_ids: [r1[:item_id], r2[:item_id], r3[:item_id]]
    )
    expect(chunk[:success]).to be true

    loaded = client.load_to_working_memory(chunk_id: chunk[:chunk_id])
    expect(loaded[:success]).to be true
    expect(loaded[:working_memory_size]).to eq(1)

    status = client.working_memory_status
    expect(status[:size]).to eq(1)
    expect(status[:load]).to be > 0.0

    report = client.chunking_report
    expect(report[:report][:chunking_efficiency]).to eq(1.0)
    expect(report[:report][:unchunked_items]).to eq(0)
  end

  it 'supports merge of two chunks into a hierarchy' do
    ra = client.add_item(content: 'opening theory')[:item_id]
    rb = client.add_item(content: 'endgame theory')[:item_id]
    ca = client.create_chunk(label: 'Opening', item_ids: [ra])[:chunk_id]
    cb = client.create_chunk(label: 'Endgame', item_ids: [rb])[:chunk_id]

    merged = client.merge_chunks(chunk_ids: [ca, cb], label: 'Chess Theory')
    expect(merged[:success]).to be true
    expect(merged[:chunk][:hierarchical]).to be true
  end

  it 'reports unchunked items correctly' do
    client.add_item(content: 'orphan item')
    r2 = client.add_item(content: 'grouped item')[:item_id]
    client.create_chunk(label: 'group', item_ids: [r2])

    result = client.unchunked_items
    expect(result[:items].size).to eq(1)
    expect(result[:items].first[:content]).to eq('orphan item')
  end
end
