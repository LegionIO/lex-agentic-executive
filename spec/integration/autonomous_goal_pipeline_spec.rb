# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Autonomous Goal Pipeline Integration' do
  let(:goal_client) { Legion::Extensions::Agentic::Executive::GoalManagement::Client.new }
  let(:bridge) do
    Legion::Extensions::Agentic::Executive::Volition::Helpers::GoalBridge.new(
      goal_client: goal_client
    )
  end
  let(:volition_client) do
    Legion::Extensions::Agentic::Executive::Volition::Client.new(
      stack:       Legion::Extensions::Agentic::Executive::Volition::Helpers::IntentionStack.new,
      goal_bridge: bridge
    )
  end

  let(:tick_results) do
    { working_memory_integration: { curiosity: { intensity: 0.9, count: 5 } } }
  end
  let(:cognitive_state) do
    { health: 0.6, pending_goals: 0, arousal: 0.5, gut: { signal: :explore },
      confidence: 0.4, pending_questions: 3, peer_interactions: 0,
      trust: { avg_composite: 0.5 } }
  end
  let(:bond_state) { {} }

  it 'flows from intention through goal to dispatch-ready state' do
    # Step 1: Form intentions (triggers goal bridge)
    volition_result = volition_client.form_intentions(
      tick_results: tick_results, cognitive_state: cognitive_state, bond_state: bond_state
    )
    expect(volition_result[:bridge_result][:bridged]).to be >= 1

    # Step 2: Verify goals were created
    goal_ids = volition_result[:bridge_result][:goal_ids]
    expect(goal_ids).not_to be_empty

    # Step 3: Auto-decompose the first goal
    first_goal_id = goal_ids.first
    goal_client.activate_goal(goal_id: first_goal_id)
    decomp = goal_client.auto_decompose_goal(goal_id: first_goal_id, strategy: :heuristic)
    expect(decomp[:success]).to be true

    # Step 4: Verify goal tree has children
    tree = goal_client.get_goal_tree(goal_id: first_goal_id)
    expect(tree[:tree]).not_to be_nil

    # Step 5: Check goal status shows goals exist
    status = goal_client.goal_status
    expect(status[:total]).to be >= 1
  end

  it 'updates goal on simulated task completion' do
    # Create and activate a leaf goal with task assignment
    add_result = goal_client.add_goal(
      content: 'simple leaf goal', domain: :general, priority: 0.5,
      parent_id: nil, deadline: nil
    )
    goal_id = add_result[:goal][:id]
    goal_client.activate_goal(goal_id: goal_id)

    engine = goal_client.send(:engine)
    goal = engine.goals[goal_id]
    goal.assign_task!(task_id: 'task-sim-001', runner_mapping: { runner_class: 'Test', function: :test })

    # Simulate task completion
    update = engine.update_from_task_event(task_id: 'task-sim-001', status: 'task.completed')
    expect(update[:found]).to be true
    expect(update[:new_status]).to eq(:completed)
    expect(goal.progress).to eq(1.0)
  end

  it 'blocks goal on simulated task failure' do
    add_result = goal_client.add_goal(
      content: 'failing goal', domain: :general, priority: 0.5,
      parent_id: nil, deadline: nil
    )
    goal_id = add_result[:goal][:id]
    goal_client.activate_goal(goal_id: goal_id)

    engine = goal_client.send(:engine)
    goal = engine.goals[goal_id]
    goal.assign_task!(task_id: 'task-fail-001', runner_mapping: { runner_class: 'Test', function: :test })

    update = engine.update_from_task_event(task_id: 'task-fail-001', status: 'task.exception')
    expect(update[:found]).to be true
    expect(update[:new_status]).to eq(:blocked)
  end

  it 'reprioritizes goals on urgency signal' do
    goal_client.add_goal(content: 'safety issue', domain: :safety, priority: 0.4, parent_id: nil, deadline: nil)
    goal_client.add_goal(content: 'general task', domain: :general, priority: 0.4, parent_id: nil, deadline: nil)

    # Activate both
    engine = goal_client.send(:engine)
    engine.goals.each_value(&:activate!)

    result = engine.reprioritize!(signal: { domain: :safety, urgency: :critical })
    expect(result[:adjusted]).to eq(1)

    safety = engine.goals.values.find { |g| g.domain == :safety }
    general = engine.goals.values.find { |g| g.domain == :general }
    expect(safety.priority).to be > general.priority
  end
end
