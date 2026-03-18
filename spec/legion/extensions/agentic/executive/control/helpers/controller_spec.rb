# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Control::Helpers::Controller do
  subject(:ctrl) { described_class.new }

  describe '#set_goal' do
    it 'creates a goal' do
      goal = ctrl.set_goal(description: 'learn Ruby')
      expect(goal).to be_a(Legion::Extensions::Agentic::Executive::Control::Helpers::Goal)
      expect(goal.description).to eq('learn Ruby')
    end

    it 'enforces MAX_GOALS' do
      20.times { |i| ctrl.set_goal(description: "goal_#{i}") }
      expect(ctrl.set_goal(description: 'overflow')).to be_nil
    end
  end

  describe '#advance_goal' do
    it 'advances the goal' do
      goal = ctrl.set_goal(description: 'test')
      result = ctrl.advance_goal(goal_id: goal.id, amount: 0.3)
      expect(result).to be_within(0.001).of(0.3)
    end

    it 'returns nil for unknown goal' do
      expect(ctrl.advance_goal(goal_id: :bogus)).to be_nil
    end
  end

  describe '#suspend_goal' do
    it 'suspends an active goal' do
      goal = ctrl.set_goal(description: 'test')
      ctrl.suspend_goal(goal_id: goal.id)
      expect(goal.state).to eq(:suspended)
    end

    it 'returns nil for unknown goal' do
      expect(ctrl.suspend_goal(goal_id: :bogus)).to be_nil
    end
  end

  describe '#resume_goal' do
    it 'resumes a suspended goal' do
      goal = ctrl.set_goal(description: 'test')
      ctrl.suspend_goal(goal_id: goal.id)
      ctrl.resume_goal(goal_id: goal.id)
      expect(goal.state).to eq(:active)
    end
  end

  describe '#abandon_goal' do
    it 'abandons a goal' do
      goal = ctrl.set_goal(description: 'test')
      ctrl.abandon_goal(goal_id: goal.id)
      expect(goal.state).to eq(:abandoned)
    end
  end

  describe '#evaluate_control_demand' do
    it 'returns signal hash' do
      result = ctrl.evaluate_control_demand(conflict: true)
      expect(result).to include(:effort_level, :mode, :conflict_detected)
      expect(result[:conflict_detected]).to be true
    end

    it 'records in history' do
      ctrl.evaluate_control_demand(error: true)
      expect(ctrl.history.size).to eq(1)
    end

    it 'resets prior detections' do
      ctrl.evaluate_control_demand(conflict: true)
      result = ctrl.evaluate_control_demand(error: true)
      expect(result[:conflict_detected]).to be false
      expect(result[:error_detected]).to be true
    end
  end

  describe '#current_mode' do
    it 'returns the signal mode' do
      expect(ctrl.current_mode).to be_a(Symbol)
    end
  end

  describe '#should_override?' do
    it 'returns false at default effort' do
      expect(ctrl.should_override?).to be false
    end

    it 'returns true after multiple boosts' do
      ctrl.evaluate_control_demand(conflict: true, error: true, novelty: true)
      expect(ctrl.should_override?).to be true
    end
  end

  describe '#should_control?' do
    it 'returns true after a boost' do
      ctrl.evaluate_control_demand(novelty: true)
      expect(ctrl.should_control?).to be true
    end
  end

  describe '#active_goals' do
    it 'returns active goals sorted by priority descending' do
      ctrl.set_goal(description: 'low', priority: 0.2)
      ctrl.set_goal(description: 'high', priority: 0.9)
      goals = ctrl.active_goals
      expect(goals.size).to eq(2)
      expect(goals.first[:priority]).to be > goals.last[:priority]
    end
  end

  describe '#top_goal' do
    it 'returns the highest-priority active goal' do
      ctrl.set_goal(description: 'low', priority: 0.2)
      ctrl.set_goal(description: 'high', priority: 0.9)
      expect(ctrl.top_goal[:description]).to eq('high')
    end

    it 'returns nil when no active goals' do
      expect(ctrl.top_goal).to be_nil
    end
  end

  describe '#goal_conflict?' do
    it 'returns false with one goal' do
      ctrl.set_goal(description: 'solo', priority: 0.5)
      expect(ctrl.goal_conflict?).to be false
    end

    it 'detects conflict with similar-priority goals' do
      ctrl.set_goal(description: 'a', priority: 0.5)
      ctrl.set_goal(description: 'b', priority: 0.6)
      expect(ctrl.goal_conflict?).to be true
    end

    it 'no conflict with very different priorities' do
      ctrl.set_goal(description: 'a', priority: 0.1)
      ctrl.set_goal(description: 'b', priority: 0.9)
      expect(ctrl.goal_conflict?).to be false
    end
  end

  describe '#tick' do
    it 'decays effort and returns signal hash' do
      ctrl.evaluate_control_demand(conflict: true)
      original = ctrl.signal.effort_level
      result = ctrl.tick
      expect(result[:effort_level]).to be < original
    end

    it 'auto-detects goal conflicts' do
      ctrl.set_goal(description: 'a', priority: 0.5)
      ctrl.set_goal(description: 'b', priority: 0.6)
      result = ctrl.tick
      expect(result[:conflict_detected]).to be true
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      expect(ctrl.to_h).to include(:goal_count, :active_goals, :effort_level, :mode,
                                   :effort_label, :goal_conflict, :history_size)
    end
  end
end
