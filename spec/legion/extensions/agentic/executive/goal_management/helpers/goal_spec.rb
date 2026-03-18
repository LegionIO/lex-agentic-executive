# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::Goal do
  subject(:goal) { described_class.new(content: 'test goal') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(goal.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets content' do
      expect(goal.content).to eq('test goal')
    end

    it 'defaults status to :proposed' do
      expect(goal.status).to eq(:proposed)
    end

    it 'defaults priority to DEFAULT_PRIORITY' do
      expect(goal.priority).to eq(0.5)
    end

    it 'defaults progress to 0.0' do
      expect(goal.progress).to eq(0.0)
    end

    it 'defaults domain to :general' do
      expect(goal.domain).to eq(:general)
    end

    it 'defaults parent_id to nil' do
      expect(goal.parent_id).to be_nil
    end

    it 'starts with empty sub_goal_ids' do
      expect(goal.sub_goal_ids).to be_empty
    end

    it 'clamps priority above 1.0' do
      g = described_class.new(content: 'x', priority: 1.5)
      expect(g.priority).to eq(1.0)
    end

    it 'clamps priority below 0.0' do
      g = described_class.new(content: 'x', priority: -0.5)
      expect(g.priority).to eq(0.0)
    end

    it 'accepts a deadline' do
      deadline = Time.now + 3600
      g = described_class.new(content: 'x', deadline: deadline)
      expect(g.deadline).to eq(deadline)
    end
  end

  describe '#activate!' do
    it 'transitions from proposed to active' do
      expect(goal.activate!).to be true
      expect(goal.status).to eq(:active)
    end

    it 'transitions from blocked to active' do
      goal.activate!
      goal.block!
      expect(goal.unblock!).to be true
      expect(goal.status).to eq(:active)
    end

    it 'returns false when already active' do
      goal.activate!
      expect(goal.activate!).to be false
    end

    it 'returns false when completed' do
      goal.activate!
      goal.complete!
      expect(goal.activate!).to be false
    end
  end

  describe '#complete!' do
    it 'transitions from active to completed' do
      goal.activate!
      expect(goal.complete!).to be true
      expect(goal.status).to eq(:completed)
    end

    it 'sets progress to 1.0 on completion' do
      goal.activate!
      goal.complete!
      expect(goal.progress).to eq(1.0)
    end

    it 'returns false when proposed' do
      expect(goal.complete!).to be false
    end
  end

  describe '#abandon!' do
    it 'abandons an active goal' do
      goal.activate!
      expect(goal.abandon!).to be true
      expect(goal.status).to eq(:abandoned)
    end

    it 'abandons a proposed goal' do
      expect(goal.abandon!).to be true
    end

    it 'returns false when already completed' do
      goal.activate!
      goal.complete!
      expect(goal.abandon!).to be false
    end

    it 'returns false when already abandoned' do
      goal.abandon!
      expect(goal.abandon!).to be false
    end
  end

  describe '#block!' do
    it 'blocks an active goal' do
      goal.activate!
      expect(goal.block!).to be true
      expect(goal.status).to eq(:blocked)
    end

    it 'returns false when proposed' do
      expect(goal.block!).to be false
    end
  end

  describe '#unblock!' do
    it 'unblocks a blocked goal' do
      goal.activate!
      goal.block!
      expect(goal.unblock!).to be true
      expect(goal.status).to eq(:active)
    end

    it 'returns false when active' do
      goal.activate!
      expect(goal.unblock!).to be false
    end
  end

  describe '#advance_progress!' do
    before { goal.activate! }

    it 'increases progress' do
      goal.advance_progress!(0.3)
      expect(goal.progress).to be_within(0.001).of(0.3)
    end

    it 'clamps progress at 1.0' do
      goal.advance_progress!(1.5)
      expect(goal.progress).to eq(1.0)
    end

    it 'returns false for completed goals' do
      goal.complete!
      expect(goal.advance_progress!(0.1)).to be false
    end

    it 'accumulates multiple advances' do
      goal.advance_progress!(0.2)
      goal.advance_progress!(0.3)
      expect(goal.progress).to be_within(0.001).of(0.5)
    end
  end

  describe '#boost_priority!' do
    it 'increases priority by PRIORITY_BOOST' do
      goal.boost_priority!
      expect(goal.priority).to be_within(0.001).of(0.6)
    end

    it 'clamps at 1.0' do
      g = described_class.new(content: 'x', priority: 0.95)
      g.boost_priority!
      expect(g.priority).to eq(1.0)
    end
  end

  describe '#decay_priority!' do
    it 'decreases priority by PRIORITY_DECAY' do
      goal.decay_priority!
      expect(goal.priority).to be_within(0.001).of(0.48)
    end

    it 'clamps at 0.0' do
      g = described_class.new(content: 'x', priority: 0.01)
      g.decay_priority!
      expect(g.priority).to eq(0.0)
    end
  end

  describe '#root?' do
    it 'returns true when parent_id is nil' do
      expect(goal.root?).to be true
    end

    it 'returns false when parent_id is set' do
      g = described_class.new(content: 'x', parent_id: 'some-id')
      expect(g.root?).to be false
    end
  end

  describe '#leaf?' do
    it 'returns true with no sub_goal_ids' do
      expect(goal.leaf?).to be true
    end

    it 'returns false after adding sub_goal' do
      goal.add_sub_goal('child-id')
      expect(goal.leaf?).to be false
    end
  end

  describe '#overdue?' do
    it 'returns false with no deadline' do
      expect(goal.overdue?).to be false
    end

    it 'returns true when deadline is in the past' do
      g = described_class.new(content: 'x', deadline: Time.now - 3600)
      expect(g.overdue?).to be true
    end

    it 'returns false when deadline is in the future' do
      g = described_class.new(content: 'x', deadline: Time.now + 3600)
      expect(g.overdue?).to be false
    end
  end

  describe '#priority_label' do
    it 'returns :critical for priority 0.9' do
      g = described_class.new(content: 'x', priority: 0.9)
      expect(g.priority_label).to eq(:critical)
    end

    it 'returns :moderate for default priority 0.5' do
      expect(goal.priority_label).to eq(:moderate)
    end

    it 'returns :trivial for low priority 0.05' do
      g = described_class.new(content: 'x', priority: 0.05)
      expect(g.priority_label).to eq(:trivial)
    end
  end

  describe '#progress_label' do
    it 'returns :not_started initially' do
      expect(goal.progress_label).to eq(:not_started)
    end

    it 'returns :complete at 1.0' do
      goal.activate!
      goal.complete!
      expect(goal.progress_label).to eq(:complete)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = goal.to_h
      expect(h).to include(:id, :content, :status, :priority, :progress, :domain, :root, :leaf, :overdue)
    end

    it 'includes priority_label and progress_label' do
      h = goal.to_h
      expect(h[:priority_label]).to eq(:moderate)
      expect(h[:progress_label]).to eq(:not_started)
    end

    it 'sub_goal_ids is a copy' do
      h = goal.to_h
      h[:sub_goal_ids] << 'injected'
      expect(goal.sub_goal_ids).to be_empty
    end
  end
end
