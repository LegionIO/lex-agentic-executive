# frozen_string_literal: true

require 'legion/extensions/agentic/executive/goal_management/client'
require 'legion/extensions/agentic/executive/volition/helpers/goal_bridge'

RSpec.describe Legion::Extensions::Agentic::Executive::Volition::Helpers::GoalBridge do
  let(:goal_client) { Legion::Extensions::Agentic::Executive::GoalManagement::Client.new }
  let(:bridge) { described_class.new(goal_client: goal_client) }

  describe '#bridge_intentions' do
    let(:intentions) do
      [
        { intention_id: 'int-001', drive: :curiosity, domain: :cognition,
          goal: 'explore knowledge gap in perception', salience: 0.8,
          state: :active, context: {} },
        { intention_id: 'int-002', drive: :corrective, domain: :safety,
          goal: 'fix degraded safety monitor', salience: 0.6,
          state: :active, context: {} }
      ]
    end

    it 'creates a goal for each active intention' do
      result = bridge.bridge_intentions(intentions)
      expect(result[:bridged]).to eq(2)
      expect(result[:goal_ids].size).to eq(2)
      expect(goal_client.list_active_goals[:goals]).to be_empty
      proposed = goal_client.goal_status[:statuses][:proposed]
      expect(proposed).to eq(2)
    end

    it 'maps salience to goal priority' do
      result = bridge.bridge_intentions(intentions)
      goals = result[:goal_ids].map { |id| goal_client.get_goal_tree(goal_id: id) }
      priorities = goals.map { |g| g[:tree][:priority] }
      expect(priorities.first).to be > priorities.last
    end

    it 'skips non-active intentions' do
      intentions[1][:state] = :suspended
      result = bridge.bridge_intentions(intentions)
      expect(result[:bridged]).to eq(1)
      expect(result[:skipped]).to eq(1)
    end

    it 'skips duplicate intentions already bridged' do
      bridge.bridge_intentions(intentions)
      result = bridge.bridge_intentions(intentions)
      expect(result[:bridged]).to eq(0)
      expect(result[:duplicates]).to eq(2)
    end

    it 'returns empty result for empty input' do
      result = bridge.bridge_intentions([])
      expect(result[:bridged]).to eq(0)
      expect(result[:goal_ids]).to be_empty
    end
  end
end
