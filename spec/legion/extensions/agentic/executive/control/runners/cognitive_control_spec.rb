# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Control::Runners::CognitiveControl do
  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#set_control_goal' do
    it 'creates a goal' do
      result = host.set_control_goal(description: 'test goal', priority: 0.8)
      expect(result[:success]).to be true
      expect(result[:goal_id]).to be_a(Symbol)
      expect(result[:priority]).to eq(0.8)
    end

    it 'returns failure when limit reached' do
      20.times { |i| host.set_control_goal(description: "g#{i}") }
      result = host.set_control_goal(description: 'overflow')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_reached)
    end
  end

  describe '#advance_control_goal' do
    it 'advances a goal' do
      created = host.set_control_goal(description: 'test')
      result = host.advance_control_goal(goal_id: created[:goal_id], amount: 0.5)
      expect(result[:success]).to be true
      expect(result[:progress]).to be_within(0.001).of(0.5)
    end

    it 'returns failure for unknown goal' do
      result = host.advance_control_goal(goal_id: :bogus)
      expect(result[:success]).to be false
    end
  end

  describe '#suspend_control_goal' do
    it 'suspends a goal' do
      created = host.set_control_goal(description: 'test')
      result = host.suspend_control_goal(goal_id: created[:goal_id])
      expect(result[:success]).to be true
    end
  end

  describe '#evaluate_control' do
    it 'evaluates control demand' do
      result = host.evaluate_control(conflict: true, error: true)
      expect(result[:success]).to be true
      expect(result[:conflict_detected]).to be true
      expect(result[:error_detected]).to be true
    end
  end

  describe '#current_control_mode' do
    it 'returns mode info' do
      result = host.current_control_mode
      expect(result[:success]).to be true
      expect(result[:mode]).to be_a(Symbol)
      expect(result).to have_key(:should_override)
      expect(result).to have_key(:should_control)
    end
  end

  describe '#active_control_goals' do
    it 'returns active goals' do
      host.set_control_goal(description: 'a')
      result = host.active_control_goals
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#top_control_goal' do
    it 'returns the top goal' do
      host.set_control_goal(description: 'important', priority: 0.9)
      result = host.top_control_goal
      expect(result[:success]).to be true
      expect(result[:description]).to eq('important')
    end

    it 'returns failure when no active goals' do
      result = host.top_control_goal
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:no_active_goals)
    end
  end

  describe '#update_cognitive_control' do
    it 'ticks the controller' do
      result = host.update_cognitive_control
      expect(result[:success]).to be true
      expect(result).to have_key(:effort_level)
    end
  end

  describe '#cognitive_control_stats' do
    it 'returns stats' do
      result = host.cognitive_control_stats
      expect(result[:success]).to be true
      expect(result).to have_key(:goal_count)
      expect(result).to have_key(:mode)
    end
  end
end
