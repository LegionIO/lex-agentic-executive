# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::FlexibilityEngine do
  subject(:engine) { described_class.new }

  let(:task_a_id) do
    result = engine.register_task(name: 'Task A', domain: :linguistic, difficulty: 0.3)
    result.id
  end

  let(:task_b_id) do
    result = engine.register_task(name: 'Task B', domain: :spatial, difficulty: 0.6)
    result.id
  end

  let(:same_domain_task_id) do
    result = engine.register_task(name: 'Task C', domain: :linguistic, difficulty: 0.4)
    result.id
  end

  describe '#register_task' do
    it 'creates and stores a TrainingTask' do
      result = engine.register_task(name: 'Vocab', domain: :linguistic, difficulty: 0.4)
      expect(result).to be_a(Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::TrainingTask)
      expect(engine.tasks.size).to eq(1)
    end

    it 'returns error for invalid domain' do
      result = engine.register_task(name: 'Bad', domain: :nonexistent, difficulty: 0.5)
      expect(result[:error]).to eq(:invalid_domain)
    end

    it 'enforces MAX_TASKS limit' do
      stub_const('Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::Constants::MAX_TASKS', 2)
      engine.register_task(name: 'T1', domain: :logical, difficulty: 0.1)
      engine.register_task(name: 'T2', domain: :logical, difficulty: 0.2)
      result = engine.register_task(name: 'T3', domain: :logical, difficulty: 0.3)
      expect(result[:error]).to eq(:max_tasks_reached)
    end
  end

  describe '#perform_switch' do
    it 'creates a SwitchTrial' do
      result = engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      expect(result).to be_a(Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::SwitchTrial)
    end

    it 'appends trial to trials list' do
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      expect(engine.trials.size).to eq(1)
    end

    it 'returns error when from_task not found' do
      result = engine.perform_switch(from_task_id: 'missing', to_task_id: task_b_id)
      expect(result[:error]).to eq(:task_not_found)
      expect(result[:missing]).to eq(:from)
    end

    it 'returns error when to_task not found' do
      result = engine.perform_switch(from_task_id: task_a_id, to_task_id: 'missing')
      expect(result[:error]).to eq(:task_not_found)
      expect(result[:missing]).to eq(:to)
    end

    it 'applies lower switch cost for same-domain switches' do
      cross_domain  = engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      same_domain   = engine.perform_switch(from_task_id: task_a_id, to_task_id: same_domain_task_id)
      expect(same_domain.switch_cost).to be < cross_domain.switch_cost
    end

    it 'increments practice_count on both tasks' do
      task_a = engine.tasks[task_a_id]
      task_b = engine.tasks[task_b_id]
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      expect(task_a.practice_count).to eq(1)
      expect(task_b.practice_count).to eq(1)
    end

    it 'enforces MAX_TRIALS limit' do
      stub_const('Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::Constants::MAX_TRIALS', 1)
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      result = engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      expect(result[:error]).to eq(:max_trials_reached)
    end
  end

  describe '#start_session / #end_session' do
    it 'groups trials into a session' do
      engine.start_session
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      engine.perform_switch(from_task_id: task_b_id, to_task_id: task_a_id)
      session = engine.end_session
      expect(session.size).to eq(2)
      expect(engine.sessions.size).to eq(1)
    end

    it 'returns nil end_session with no active session' do
      expect(engine.end_session).to be_nil
    end

    it 'clears current session after end' do
      engine.start_session
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      engine.end_session
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      expect(engine.sessions.first.size).to eq(1)
    end
  end

  describe '#average_switch_cost' do
    it 'returns 0.0 with no trials' do
      expect(engine.average_switch_cost).to eq(0.0)
    end

    it 'computes average over recent trials' do
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      engine.perform_switch(from_task_id: task_b_id, to_task_id: task_a_id)
      cost = engine.average_switch_cost
      expect(cost).to be_between(0.0, 1.0)
    end
  end

  describe '#switch_cost_between' do
    it 'returns 0.0 for unknown pair' do
      expect(engine.switch_cost_between(from_id: 'x', to_id: 'y')).to eq(0.0)
    end

    it 'returns average cost for a specific pair' do
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      cost = engine.switch_cost_between(from_id: task_a_id, to_id: task_b_id)
      expect(cost).to be_between(0.0, 1.0)
    end
  end

  describe '#improvement_rate' do
    it 'returns 0.0 with fewer than 4 trials' do
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      expect(engine.improvement_rate).to eq(0.0)
    end

    it 'returns a numeric rate with enough trials' do
      8.times { engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id) }
      expect(engine.improvement_rate).to be_a(Numeric)
    end
  end

  describe '#flexibility_score' do
    it 'returns 1.0 with no trials' do
      expect(engine.flexibility_score).to eq(1.0)
    end

    it 'is the complement of average_switch_cost' do
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      expect(engine.flexibility_score.round(8)).to eq((1.0 - engine.average_switch_cost).round(8))
    end
  end

  describe '#hardest_switches / #easiest_switches' do
    before do
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
      engine.perform_switch(from_task_id: task_b_id, to_task_id: task_a_id)
    end

    it 'returns hardest switches sorted by cost descending' do
      results = engine.hardest_switches(limit: 2)
      expect(results).to be_an(Array)
      costs = results.map { |r| r[:average_switch_cost] }
      expect(costs).to eq(costs.sort.reverse)
    end

    it 'returns easiest switches sorted by cost ascending' do
      results = engine.easiest_switches(limit: 2)
      costs = results.map { |r| r[:average_switch_cost] }
      expect(costs).to eq(costs.sort)
    end

    it 'respects the limit parameter' do
      expect(engine.hardest_switches(limit: 1).size).to eq(1)
    end
  end

  describe '#training_report' do
    before do
      engine.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id)
    end

    it 'includes key report fields' do
      report = engine.training_report
      expect(report).to include(:task_count, :trial_count, :session_count,
                                :average_switch_cost, :flexibility_score,
                                :improvement_rate, :flexibility_label, :progress_label,
                                :costly_trial_ratio, :successful_trial_ratio)
    end

    it 'reflects correct counts' do
      report = engine.training_report
      expect(report[:task_count]).to eq(2)
      expect(report[:trial_count]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'includes tasks, trials, sessions, and report keys' do
      h = engine.to_h
      expect(h).to include(:tasks, :trials, :sessions, :report)
    end
  end
end
