# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::GoalEngine do
  subject(:engine) { described_class.new }

  def add_active_goal(content: 'goal', domain: :general, priority: 0.5)
    result = engine.add_goal(content: content, domain: domain, priority: priority)
    engine.activate_goal(goal_id: result[:goal][:id])
    result[:goal][:id]
  end

  describe '#add_goal' do
    it 'adds a root goal' do
      result = engine.add_goal(content: 'root goal')
      expect(result[:success]).to be true
      expect(result[:goal][:content]).to eq('root goal')
    end

    it 'assigns a UUID id' do
      result = engine.add_goal(content: 'root')
      expect(result[:goal][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'tracks root goal ids' do
      result = engine.add_goal(content: 'root')
      expect(engine.root_goal_ids).to include(result[:goal][:id])
    end

    it 'adds a sub-goal under a parent' do
      parent = engine.add_goal(content: 'parent')
      child = engine.add_goal(content: 'child', parent_id: parent[:goal][:id])
      expect(child[:success]).to be true
      expect(child[:goal][:parent_id]).to eq(parent[:goal][:id])
    end

    it 'does not track sub-goals as root goals' do
      parent = engine.add_goal(content: 'parent')
      child = engine.add_goal(content: 'child', parent_id: parent[:goal][:id])
      expect(engine.root_goal_ids).not_to include(child[:goal][:id])
    end

    it 'fails when parent does not exist' do
      result = engine.add_goal(content: 'orphan', parent_id: 'nonexistent-id')
      expect(result[:success]).to be false
      expect(result[:error]).to include('not found')
    end

    it 'accepts deadline parameter' do
      deadline = Time.now + 3600
      result = engine.add_goal(content: 'goal', deadline: deadline)
      expect(result[:goal][:deadline]).to eq(deadline)
    end
  end

  describe '#decompose' do
    it 'creates sub-goals under a parent' do
      parent = engine.add_goal(content: 'parent')
      result = engine.decompose(goal_id: parent[:goal][:id], sub_goals: [
                                  { content: 'sub1' },
                                  { content: 'sub2' }
                                ])
      expect(result[:success]).to be true
      expect(result[:created].size).to eq(2)
    end

    it 'fails with nonexistent parent' do
      result = engine.decompose(goal_id: 'nonexistent', sub_goals: [{ content: 'x' }])
      expect(result[:success]).to be false
    end

    it 'passes parent domain to sub-goals by default' do
      parent = engine.add_goal(content: 'parent', domain: :coding)
      result = engine.decompose(goal_id: parent[:goal][:id], sub_goals: [{ content: 'sub' }])
      sub_id = result[:created].first[:goal][:id]
      sub = engine.goals[sub_id]
      expect(sub.domain).to eq(:coding)
    end

    it 'allows custom domain on sub-goals' do
      parent = engine.add_goal(content: 'parent', domain: :coding)
      result = engine.decompose(goal_id: parent[:goal][:id], sub_goals: [{ content: 'sub', domain: :ops }])
      sub_id = result[:created].first[:goal][:id]
      sub = engine.goals[sub_id]
      expect(sub.domain).to eq(:ops)
    end
  end

  describe '#activate_goal' do
    it 'activates a proposed goal' do
      id = engine.add_goal(content: 'goal')[:goal][:id]
      result = engine.activate_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:active)
    end

    it 'fails with nonexistent goal' do
      result = engine.activate_goal(goal_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '#complete_goal' do
    it 'completes an active goal' do
      id = add_active_goal
      result = engine.complete_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:completed)
    end

    it 'fails for a proposed goal' do
      id = engine.add_goal(content: 'goal')[:goal][:id]
      result = engine.complete_goal(goal_id: id)
      expect(result[:success]).to be false
    end
  end

  describe '#abandon_goal' do
    it 'abandons an active goal' do
      id = add_active_goal
      result = engine.abandon_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:abandoned)
    end
  end

  describe '#block_goal' do
    it 'blocks an active goal' do
      id = add_active_goal
      result = engine.block_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:blocked)
    end

    it 'fails for a proposed goal' do
      id = engine.add_goal(content: 'goal')[:goal][:id]
      result = engine.block_goal(goal_id: id)
      expect(result[:success]).to be false
    end
  end

  describe '#unblock_goal' do
    it 'unblocks a blocked goal' do
      id = add_active_goal
      engine.block_goal(goal_id: id)
      result = engine.unblock_goal(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:active)
    end
  end

  describe '#advance_progress' do
    it 'advances goal progress' do
      id = add_active_goal
      result = engine.advance_progress(goal_id: id, amount: 0.4)
      expect(result[:success]).to be true
      expect(result[:progress]).to be_within(0.001).of(0.4)
    end

    it 'propagates average progress to parent' do
      parent_id = engine.add_goal(content: 'parent')[:goal][:id]
      engine.activate_goal(goal_id: parent_id)
      child1 = engine.add_goal(content: 'c1', parent_id: parent_id)[:goal][:id]
      child2 = engine.add_goal(content: 'c2', parent_id: parent_id)[:goal][:id]
      engine.activate_goal(goal_id: child1)
      engine.activate_goal(goal_id: child2)

      engine.advance_progress(goal_id: child1, amount: 0.6)
      engine.advance_progress(goal_id: child2, amount: 0.4)

      parent = engine.goals[parent_id]
      expect(parent.progress).to be_within(0.001).of(0.5)
    end

    it 'fails for nonexistent goal' do
      result = engine.advance_progress(goal_id: 'nonexistent', amount: 0.5)
      expect(result[:success]).to be false
    end
  end

  describe '#detect_conflicts' do
    it 'returns empty conflicts when alone in domain' do
      id = add_active_goal(domain: :unique_domain)
      result = engine.detect_conflicts(goal_id: id)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'detects conflicts within same domain' do
      id1 = add_active_goal(content: 'goal1', domain: :work, priority: 0.8)
      add_active_goal(content: 'goal2', domain: :work, priority: 0.8)

      result = engine.detect_conflicts(goal_id: id1)
      expect(result[:count]).to be >= 1
    end

    it 'does not conflict across different domains' do
      id1 = add_active_goal(content: 'goal1', domain: :work)
      add_active_goal(content: 'goal2', domain: :personal)

      result = engine.detect_conflicts(goal_id: id1)
      expect(result[:count]).to eq(0)
    end

    it 'returns conflict score and label' do
      id1 = add_active_goal(content: 'goal1', domain: :shared, priority: 0.9)
      add_active_goal(content: 'goal2', domain: :shared, priority: 0.9)
      result = engine.detect_conflicts(goal_id: id1)
      if result[:count] > 0
        conflict = result[:conflicts].first
        expect(conflict).to have_key(:conflict_score)
        expect(conflict).to have_key(:label)
      end
    end

    it 'fails for nonexistent goal' do
      result = engine.detect_conflicts(goal_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '#active_goals' do
    it 'returns only active goals' do
      add_active_goal(content: 'active')
      engine.add_goal(content: 'proposed only')
      expect(engine.active_goals.size).to eq(1)
    end
  end

  describe '#blocked_goals' do
    it 'returns only blocked goals' do
      id = add_active_goal
      engine.block_goal(goal_id: id)
      expect(engine.blocked_goals.size).to eq(1)
    end
  end

  describe '#overdue_goals' do
    it 'returns goals with past deadlines' do
      engine.add_goal(content: 'overdue', deadline: Time.now - 3600)
      expect(engine.overdue_goals.size).to be >= 1
    end

    it 'does not include goals with future deadlines' do
      engine.add_goal(content: 'future', deadline: Time.now + 3600)
      expect(engine.overdue_goals).to be_empty
    end
  end

  describe '#completed_goals' do
    it 'returns only completed goals' do
      id = add_active_goal
      engine.complete_goal(goal_id: id)
      expect(engine.completed_goals.size).to eq(1)
    end
  end

  describe '#goal_tree' do
    it 'returns tree for a root goal' do
      parent_id = engine.add_goal(content: 'root')[:goal][:id]
      engine.add_goal(content: 'child', parent_id: parent_id)
      result = engine.goal_tree(goal_id: parent_id)
      expect(result[:success]).to be true
      expect(result[:tree][:children]).not_to be_empty
    end

    it 'returns children recursively' do
      root_id = engine.add_goal(content: 'root')[:goal][:id]
      child_id = engine.add_goal(content: 'child', parent_id: root_id)[:goal][:id]
      engine.add_goal(content: 'grandchild', parent_id: child_id)
      result = engine.goal_tree(goal_id: root_id)
      expect(result[:tree][:children].first[:children]).not_to be_empty
    end

    it 'fails for nonexistent goal' do
      result = engine.goal_tree(goal_id: 'nonexistent')
      expect(result[:success]).to be false
    end
  end

  describe '#highest_priority' do
    it 'returns goals sorted by priority descending' do
      engine.add_goal(content: 'low', priority: 0.2)
      engine.add_goal(content: 'high', priority: 0.9)
      engine.add_goal(content: 'med', priority: 0.5)

      goals = engine.highest_priority(limit: 3)
      priorities = goals.map(&:priority)
      expect(priorities).to eq(priorities.sort.reverse)
    end

    it 'limits the result count' do
      5.times { |i| engine.add_goal(content: "goal #{i}", priority: rand) }
      goals = engine.highest_priority(limit: 3)
      expect(goals.size).to be <= 3
    end

    it 'excludes completed goals' do
      id = add_active_goal(priority: 1.0)
      engine.complete_goal(goal_id: id)
      goals = engine.highest_priority(limit: 5)
      expect(goals.none? { |g| g.id == id }).to be true
    end
  end

  describe '#decay_all_priorities!' do
    it 'decays inactive goals' do
      engine.add_goal(content: 'proposed', priority: 0.5)
      engine.add_goal(content: 'proposed2', priority: 0.5)
      result = engine.decay_all_priorities!
      expect(result[:decayed]).to be >= 2
    end

    it 'does not decay active goals' do
      id = add_active_goal(priority: 0.5)
      engine.decay_all_priorities!
      goal = engine.goals[id]
      expect(goal.priority).to eq(0.5)
    end
  end

  describe '#goal_report' do
    it 'reports total goal count' do
      3.times { engine.add_goal(content: 'goal') }
      report = engine.goal_report
      expect(report[:total]).to eq(3)
    end

    it 'includes status breakdown' do
      engine.add_goal(content: 'goal')
      report = engine.goal_report
      expect(report[:statuses]).to have_key(:proposed)
      expect(report[:statuses]).to have_key(:active)
    end

    it 'counts overdue goals' do
      engine.add_goal(content: 'overdue', deadline: Time.now - 3600)
      report = engine.goal_report
      expect(report[:overdue]).to be >= 1
    end

    it 'counts high priority goals' do
      engine.add_goal(content: 'high', priority: 0.8)
      engine.add_goal(content: 'low', priority: 0.3)
      report = engine.goal_report
      expect(report[:high_priority]).to be >= 1
    end
  end

  describe '#to_h' do
    it 'returns complete engine state' do
      engine.add_goal(content: 'goal')
      h = engine.to_h
      expect(h).to have_key(:goals)
      expect(h).to have_key(:root_goal_ids)
      expect(h).to have_key(:report)
    end
  end
end
