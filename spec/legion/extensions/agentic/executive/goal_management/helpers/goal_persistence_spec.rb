# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::GoalPersistence do
  let(:persistence) { described_class.new(namespace: 'test_goals') }

  before do
    stub_const('Legion::Cache', Class.new do
      def self.connected? = true
      def self.get(key) = (@store ||= {})[key]
      def self.set(key, value, **_opts) = ((@store ||= {})[key] = value)
      def self.set_sync(key, value, **_opts) = ((@store ||= {})[key] = value)
      def self.delete(key, **_opts) = (@store ||= {}).delete(key)
      def self.delete_sync(key) = (@store ||= {}).delete(key)
      def self.flush = (@store = {})
    end)
    Legion::Cache.flush
  end

  describe '#save_goal / #load_goal' do
    it 'round-trips a goal hash' do
      goal_hash = { id: 'g-001', content: 'test', domain: :safety, priority: 0.7,
                    status: :active, progress: 0.0, sub_goal_ids: [] }
      persistence.save_goal(goal_hash)
      loaded = persistence.load_goal('g-001')
      expect(loaded[:content]).to eq('test')
      # JSON round-trip: symbol values become strings; Goal.from_h re-symbolizes via to_sym
      expect(loaded[:domain].to_sym).to eq(:safety)
    end

    it 'returns nil for missing goal' do
      expect(persistence.load_goal('nonexistent')).to be_nil
    end

    it 'updates the index on save' do
      persistence.save_goal({ id: 'g-idx', content: 'indexed', domain: :general,
                              priority: 0.5, status: :proposed, progress: 0.0, sub_goal_ids: [] })
      all = persistence.load_all
      expect(all.keys).to include('g-idx')
    end
  end

  describe '#save_all / #load_all' do
    it 'round-trips multiple goals' do
      goals = {
        'g-001' => { id: 'g-001', content: 'goal one', domain: :safety, priority: 0.5,
                     status: :active, progress: 0.0, sub_goal_ids: [] },
        'g-002' => { id: 'g-002', content: 'goal two', domain: :cognition, priority: 0.8,
                     status: :proposed, progress: 0.0, sub_goal_ids: [] }
      }
      persistence.save_all(goals)
      loaded = persistence.load_all
      expect(loaded.size).to eq(2)
      expect(loaded['g-001'][:content]).to eq('goal one')
    end

    it 'returns empty hash when nothing saved' do
      expect(persistence.load_all).to eq({})
    end
  end

  describe '#delete_goal' do
    it 'removes a goal from cache' do
      persistence.save_goal({ id: 'g-del', content: 'delete me', domain: :general,
                              priority: 0.5, status: :active, progress: 0.0, sub_goal_ids: [] })
      persistence.delete_goal('g-del')
      expect(persistence.load_goal('g-del')).to be_nil
    end

    it 'removes the goal id from the index' do
      persistence.save_goal({ id: 'g-rm', content: 'remove from index', domain: :general,
                              priority: 0.5, status: :active, progress: 0.0, sub_goal_ids: [] })
      persistence.delete_goal('g-rm')
      all = persistence.load_all
      expect(all.keys).not_to include('g-rm')
    end
  end

  describe '#save_bridge_state / #load_bridge_state' do
    it 'round-trips bridge tracking hash' do
      # JSON round-trip with symbolize_names: true turns string keys into symbols
      state = { 'curiosity:cognition:explore gaps' => 'g-001' }
      persistence.save_bridge_state(state)
      loaded = persistence.load_bridge_state
      expect(loaded.values.first).to eq('g-001')
    end

    it 'returns empty hash when nothing saved' do
      expect(persistence.load_bridge_state).to eq({})
    end
  end

  describe 'when cache unavailable' do
    before { allow(Legion::Cache).to receive(:connected?).and_return(false) }

    it 'returns nil on load_goal' do
      expect(persistence.load_goal('g-001')).to be_nil
    end

    it 'returns false on save_goal' do
      expect(persistence.save_goal({ id: 'g-001', content: 'x' })).to be false
    end

    it 'returns empty hash on load_all' do
      expect(persistence.load_all).to eq({})
    end

    it 'returns empty hash on load_bridge_state' do
      expect(persistence.load_bridge_state).to eq({})
    end

    it 'returns false on save_bridge_state' do
      expect(persistence.save_bridge_state({ 'k' => 'v' })).to be false
    end

    it 'returns false on delete_goal' do
      expect(persistence.delete_goal('g-001')).to be false
    end
  end
end
