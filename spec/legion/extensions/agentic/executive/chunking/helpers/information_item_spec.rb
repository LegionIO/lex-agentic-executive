# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Chunking::Helpers::InformationItem do
  let(:item) { described_class.new(content: 'bishop controls e4', domain: :chess) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(item.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(item.content).to eq('bishop controls e4')
    end

    it 'stores domain' do
      expect(item.domain).to eq(:chess)
    end

    it 'defaults chunked to false' do
      expect(item.chunked?).to be false
    end

    it 'defaults chunk_id to nil' do
      expect(item.chunk_id).to be_nil
    end

    it 'sets created_at' do
      expect(item.created_at).to be_a(Time)
    end

    it 'defaults domain to :general' do
      plain = described_class.new(content: 'hello')
      expect(plain.domain).to eq(:general)
    end
  end

  describe '#assign_to_chunk!' do
    it 'marks item as chunked' do
      item.assign_to_chunk!(chunk_id: 'abc-123')
      expect(item.chunked?).to be true
    end

    it 'stores the chunk_id' do
      item.assign_to_chunk!(chunk_id: 'abc-123')
      expect(item.chunk_id).to eq('abc-123')
    end
  end

  describe '#unchunk!' do
    before { item.assign_to_chunk!(chunk_id: 'abc-123') }

    it 'clears chunked flag' do
      item.unchunk!
      expect(item.chunked?).to be false
    end

    it 'clears chunk_id' do
      item.unchunk!
      expect(item.chunk_id).to be_nil
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = item.to_h
      expect(h.keys).to contain_exactly(:id, :content, :domain, :chunked, :chunk_id, :created_at)
    end

    it 'reflects chunked state' do
      item.assign_to_chunk!(chunk_id: 'xyz')
      expect(item.to_h[:chunked]).to be true
      expect(item.to_h[:chunk_id]).to eq('xyz')
    end
  end
end
