# frozen_string_literal: true

require 'legion/extensions/agentic/executive/goal_management/client'

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:add_goal)
    expect(client).to respond_to(:decompose_goal)
    expect(client).to respond_to(:activate_goal)
    expect(client).to respond_to(:complete_goal)
    expect(client).to respond_to(:abandon_goal)
    expect(client).to respond_to(:block_goal)
    expect(client).to respond_to(:unblock_goal)
    expect(client).to respond_to(:advance_goal_progress)
    expect(client).to respond_to(:detect_goal_conflicts)
    expect(client).to respond_to(:list_active_goals)
    expect(client).to respond_to(:list_blocked_goals)
    expect(client).to respond_to(:list_overdue_goals)
    expect(client).to respond_to(:list_completed_goals)
    expect(client).to respond_to(:get_goal_tree)
    expect(client).to respond_to(:highest_priority_goals)
    expect(client).to respond_to(:decay_priorities)
    expect(client).to respond_to(:goal_status)
  end

  it 'isolates state between instances' do
    c1 = described_class.new
    c2 = described_class.new
    c1.add_goal(content: 'only in c1')
    expect(c2.goal_status[:total]).to eq(0)
  end
end
