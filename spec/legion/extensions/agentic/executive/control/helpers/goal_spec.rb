# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Control::Helpers::Goal do
  subject(:goal) { described_class.new(id: :goal_one, description: 'finish report', priority: 0.7) }

  describe '#initialize' do
    it 'sets attributes' do
      expect(goal.id).to eq(:goal_one)
      expect(goal.description).to eq('finish report')
      expect(goal.priority).to eq(0.7)
      expect(goal.state).to eq(:active)
      expect(goal.progress).to eq(0.0)
    end

    it 'clamps priority' do
      g = described_class.new(id: :g, description: 'x', priority: 2.0)
      expect(g.priority).to eq(1.0)
    end

    it 'defaults domain to :general' do
      expect(goal.domain).to eq(:general)
    end
  end

  describe '#advance' do
    it 'increases progress' do
      goal.advance(amount: 0.3)
      expect(goal.progress).to eq(0.3)
    end

    it 'caps progress at 1.0' do
      goal.advance(amount: 1.5)
      expect(goal.progress).to eq(1.0)
    end

    it 'auto-completes when progress reaches 1.0' do
      goal.advance(amount: 1.0)
      expect(goal.state).to eq(:completed)
    end

    it 'returns nil when not active' do
      goal.suspend!
      expect(goal.advance(amount: 0.1)).to be_nil
    end
  end

  describe 'state transitions' do
    it '#suspend! changes active to suspended' do
      goal.suspend!
      expect(goal.state).to eq(:suspended)
    end

    it '#resume! changes suspended back to active' do
      goal.suspend!
      goal.resume!
      expect(goal.state).to eq(:active)
    end

    it '#resume! does nothing if not suspended' do
      goal.resume!
      expect(goal.state).to eq(:active)
    end

    it '#abandon! changes to abandoned' do
      goal.abandon!
      expect(goal.state).to eq(:abandoned)
    end

    it '#abandon! cannot abandon completed goal' do
      goal.advance(amount: 1.0)
      goal.abandon!
      expect(goal.state).to eq(:completed)
    end

    it '#complete! transitions to completed' do
      goal.complete!
      expect(goal.completed?).to be true
    end
  end

  describe '#active? and #completed?' do
    it 'returns true for active goal' do
      expect(goal.active?).to be true
      expect(goal.completed?).to be false
    end

    it 'returns true for completed goal' do
      goal.complete!
      expect(goal.active?).to be false
      expect(goal.completed?).to be true
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      expect(goal.to_h).to include(:id, :description, :domain, :priority, :state, :progress)
    end
  end
end
