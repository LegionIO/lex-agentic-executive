# frozen_string_literal: true

require 'legion/extensions/agentic/executive/goal_management/client'

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Runners::GoalManagement do
  let(:client) { Legion::Extensions::Agentic::Executive::GoalManagement::Client.new }

  def add_active(content: 'active goal', domain: :general, priority: 0.5)
    result = client.add_goal(content: content, domain: domain, priority: priority)
    client.activate_goal(goal_id: result[:goal][:id])
    result[:goal][:id]
  end

  describe '#add_goal' do
    it 'returns success: true with a goal hash' do
      result = client.add_goal(content: 'test goal')
      expect(result[:success]).to be true
      expect(result[:goal]).to have_key(:id)
    end

    it 'accepts domain and priority' do
      result = client.add_goal(content: 'goal', domain: :work, priority: 0.8)
      expect(result[:goal][:domain]).to eq(:work)
      expect(result[:goal][:priority]).to eq(0.8)
    end

    it 'adds sub-goal with parent_id' do
      parent = client.add_goal(content: 'parent')
      child = client.add_goal(content: 'child', parent_id: parent[:goal][:id])
      expect(child[:success]).to be true
      expect(child[:goal][:parent_id]).to eq(parent[:goal][:id])
    end

    it 'fails with nonexistent parent' do
      result = client.add_goal(content: 'orphan', parent_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '#decompose_goal' do
    it 'creates sub-goals' do
      parent = client.add_goal(content: 'parent')
      result = client.decompose_goal(goal_id: parent[:goal][:id], sub_goals: [
                                       { content: 'step 1' },
                                       { content: 'step 2' }
                                     ])
      expect(result[:success]).to be true
      expect(result[:created].size).to eq(2)
    end

    it 'fails for nonexistent goal' do
      result = client.decompose_goal(goal_id: 'nonexistent', sub_goals: [{ content: 'x' }])
      expect(result[:success]).to be false
    end
  end

  describe '#activate_goal' do
    it 'activates a proposed goal' do
      result = client.add_goal(content: 'goal')
      activate = client.activate_goal(goal_id: result[:goal][:id])
      expect(activate[:success]).to be true
      expect(activate[:status]).to eq(:active)
    end

    it 'fails for nonexistent goal' do
      result = client.activate_goal(goal_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '#complete_goal' do
    it 'completes an active goal' do
      id = add_active
      result = client.complete_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:completed)
    end

    it 'fails for a proposed goal' do
      result = client.add_goal(content: 'proposed')
      r = client.complete_goal(goal_id: result[:goal][:id])
      expect(r[:success]).to be false
    end
  end

  describe '#abandon_goal' do
    it 'abandons an active goal' do
      id = add_active
      result = client.abandon_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:abandoned)
    end
  end

  describe '#block_goal' do
    it 'blocks an active goal' do
      id = add_active
      result = client.block_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:blocked)
    end
  end

  describe '#unblock_goal' do
    it 'unblocks a blocked goal' do
      id = add_active
      client.block_goal(goal_id: id)
      result = client.unblock_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:active)
    end
  end

  describe '#advance_goal_progress' do
    it 'advances progress' do
      id = add_active
      result = client.advance_goal_progress(goal_id: id, amount: 0.5)
      expect(result[:success]).to be true
      expect(result[:progress]).to be_within(0.001).of(0.5)
    end

    it 'fails for nonexistent goal' do
      result = client.advance_goal_progress(goal_id: 'nonexistent', amount: 0.5)
      expect(result[:success]).to be false
    end
  end

  describe '#detect_goal_conflicts' do
    it 'detects no conflicts when alone in domain' do
      id = add_active(domain: :isolated_domain)
      result = client.detect_goal_conflicts(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'detects conflicts in same domain' do
      id1 = add_active(content: 'g1', domain: :crowded, priority: 0.9)
      add_active(content: 'g2', domain: :crowded, priority: 0.9)
      result = client.detect_goal_conflicts(goal_id: id1)
      expect(result[:count]).to be >= 1
    end
  end

  describe '#list_active_goals' do
    it 'returns active goals' do
      add_active
      result = client.list_active_goals
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
    end

    it 'returns empty when none active' do
      client.add_goal(content: 'proposed only')
      result = client.list_active_goals
      expect(result[:count]).to eq(0)
    end
  end

  describe '#list_blocked_goals' do
    it 'returns blocked goals' do
      id = add_active
      client.block_goal(goal_id: id)
      result = client.list_blocked_goals
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
    end
  end

  describe '#list_overdue_goals' do
    it 'returns overdue goals' do
      client.add_goal(content: 'overdue', deadline: Time.now - 3600)
      result = client.list_overdue_goals
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
    end

    it 'returns empty when no overdue goals' do
      client.add_goal(content: 'future', deadline: Time.now + 3600)
      result = client.list_overdue_goals
      expect(result[:count]).to eq(0)
    end
  end

  describe '#list_completed_goals' do
    it 'returns completed goals' do
      id = add_active
      client.complete_goal(goal_id: id)
      result = client.list_completed_goals
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
    end
  end

  describe '#get_goal_tree' do
    it 'returns tree with children' do
      parent = client.add_goal(content: 'root')
      client.add_goal(content: 'child', parent_id: parent[:goal][:id])
      result = client.get_goal_tree(goal_id: parent[:goal][:id])
      expect(result[:success]).to be true
      expect(result[:tree][:children]).not_to be_empty
    end

    it 'fails for nonexistent goal' do
      result = client.get_goal_tree(goal_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '#highest_priority_goals' do
    it 'returns goals sorted by priority' do
      client.add_goal(content: 'low', priority: 0.2)
      client.add_goal(content: 'high', priority: 0.9)
      result = client.highest_priority_goals(limit: 5)
      expect(result[:success]).to be true
      priorities = result[:goals].map { |g| g[:priority] }
      expect(priorities).to eq(priorities.sort.reverse)
    end

    it 'respects limit' do
      5.times { |i| client.add_goal(content: "goal #{i}") }
      result = client.highest_priority_goals(limit: 3)
      expect(result[:count]).to be <= 3
    end
  end

  describe '#decay_priorities' do
    it 'decays inactive goals' do
      client.add_goal(content: 'inactive')
      result = client.decay_priorities
      expect(result[:success]).to be true
      expect(result[:decayed]).to be >= 1
    end
  end

  describe '#goal_status' do
    it 'returns summary report' do
      client.add_goal(content: 'goal')
      result = client.goal_status
      expect(result[:success]).to be true
      expect(result[:total]).to be >= 1
      expect(result).to have_key(:statuses)
    end
  end
end
