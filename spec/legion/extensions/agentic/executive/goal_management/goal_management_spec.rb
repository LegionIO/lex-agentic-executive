# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement do
  it 'has a version' do
    expect(Legion::Extensions::Agentic::Executive::GoalManagement::VERSION).to eq('0.1.0')
  end

  it 'defines GOAL_STATUSES' do
    expect(Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::Constants::GOAL_STATUSES).to include(:proposed, :active, :completed)
  end
end
