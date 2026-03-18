# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Volition::Helpers::IntentionStack do
  subject(:stack) { described_class.new }

  let(:intention_mod) { Legion::Extensions::Agentic::Executive::Volition::Helpers::Intention }

  def make_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.5)
    intention_mod.new_intention(drive: drive, domain: domain, goal: goal, salience: salience)
  end

  describe '#push' do
    it 'adds an intention' do
      expect(stack.push(make_intention)).to eq(:pushed)
      expect(stack.size).to eq(1)
    end

    it 'rejects duplicates' do
      stack.push(make_intention(goal: 'same goal'))
      expect(stack.push(make_intention(goal: 'same goal'))).to eq(:duplicate)
    end

    it 'rejects when at capacity' do
      Legion::Extensions::Agentic::Executive::Volition::Helpers::Constants::MAX_INTENTIONS.times do |i|
        stack.push(make_intention(goal: "goal #{i}"))
      end
      expect(stack.push(make_intention(goal: 'overflow'))).to eq(:capacity_full)
    end

    it 'sorts by salience descending' do
      stack.push(make_intention(goal: 'low', salience: 0.3))
      stack.push(make_intention(goal: 'high', salience: 0.9))
      expect(stack.top[:goal]).to eq('high')
    end
  end

  describe '#active' do
    it 'returns only active intentions' do
      stack.push(make_intention(goal: 'active', salience: 0.5))
      stack.push(make_intention(goal: 'completed', salience: 0.8))
      stack.complete(stack.top[:intention_id])
      expect(stack.active.size).to eq(1)
    end
  end

  describe '#top' do
    it 'returns highest-salience active intention' do
      stack.push(make_intention(goal: 'low', salience: 0.3))
      stack.push(make_intention(goal: 'high', salience: 0.9))
      expect(stack.top[:goal]).to eq('high')
    end

    it 'returns nil when empty' do
      expect(stack.top).to be_nil
    end
  end

  describe '#by_drive' do
    it 'filters by drive type' do
      stack.push(make_intention(drive: :curiosity, goal: 'c1'))
      stack.push(make_intention(drive: :urgency, goal: 'u1'))
      expect(stack.by_drive(:curiosity).size).to eq(1)
    end
  end

  describe '#complete' do
    it 'marks an intention as completed' do
      stack.push(make_intention(goal: 'task'))
      id = stack.top[:intention_id]
      expect(stack.complete(id)).to eq(:completed)
      expect(stack.active).to be_empty
    end

    it 'returns :not_found for unknown id' do
      expect(stack.complete('nonexistent')).to eq(:not_found)
    end
  end

  describe '#suspend and #resume' do
    it 'suspends and resumes' do
      stack.push(make_intention(goal: 'task'))
      id = stack.top[:intention_id]

      expect(stack.suspend(id)).to eq(:suspended)
      expect(stack.active).to be_empty

      expect(stack.resume(id)).to eq(:resumed)
      expect(stack.active.size).to eq(1)
    end
  end

  describe '#decay_all' do
    it 'decays active intentions and expires low-salience ones' do
      stack.push(make_intention(goal: 'fading', salience: 0.12))
      # First decay: 0.12 - 0.05 = 0.07 < floor(0.1), so expires immediately
      expired = stack.decay_all
      expect(expired).to be >= 1
      expect(stack.active_count).to eq(0)
    end

    it 'preserves high-salience intentions through decay' do
      stack.push(make_intention(goal: 'strong', salience: 0.8))
      stack.decay_all
      expect(stack.active_count).to eq(1)
      expect(stack.top[:salience]).to be < 0.8
    end
  end

  describe '#reinforce' do
    it 'increases intention salience' do
      stack.push(make_intention(goal: 'task', salience: 0.5))
      id = stack.top[:intention_id]
      stack.reinforce(id, amount: 0.2)
      expect(stack.find(id)[:salience]).to eq(0.7)
    end
  end

  describe '#stats' do
    it 'returns comprehensive stats' do
      stack.push(make_intention(drive: :curiosity, goal: 'c1', salience: 0.8))
      stack.push(make_intention(drive: :urgency, goal: 'u1', salience: 0.6))
      stats = stack.stats
      expect(stats[:total]).to eq(2)
      expect(stats[:active]).to eq(2)
      expect(stats[:by_drive][:curiosity]).to eq(1)
      expect(stats[:top_intention][:goal]).to eq('c1')
    end
  end
end
