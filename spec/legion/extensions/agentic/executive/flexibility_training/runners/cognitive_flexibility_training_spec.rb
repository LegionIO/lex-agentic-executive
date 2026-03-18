# frozen_string_literal: true

require 'legion/extensions/agentic/executive/flexibility_training/client'

RSpec.describe Legion::Extensions::Agentic::Executive::FlexibilityTraining::Runners::CognitiveFlexibilityTraining do
  let(:engine) { Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::FlexibilityEngine.new }
  let(:client) { Legion::Extensions::Agentic::Executive::FlexibilityTraining::Client.new(engine: engine) }

  let(:task_a_id) do
    result = client.register_task(name: 'Vocabulary', domain: :linguistic, difficulty: 0.3, engine: engine)
    result[:task][:id]
  end

  let(:task_b_id) do
    result = client.register_task(name: 'Rotation', domain: :spatial, difficulty: 0.7, engine: engine)
    result[:task][:id]
  end

  describe '#register_task' do
    it 'returns success true with a task hash' do
      result = client.register_task(name: 'Math Facts', domain: :numerical, difficulty: 0.4, engine: engine)
      expect(result[:success]).to be true
      expect(result[:task]).to include(:id, :name, :domain, :difficulty)
    end

    it 'returns success false for invalid domain' do
      result = client.register_task(name: 'Bad', domain: :bogus, difficulty: 0.5, engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_domain)
    end
  end

  describe '#perform_switch' do
    it 'returns success true with a trial hash' do
      result = client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:trial]).to include(:id, :switch_cost, :accuracy, :switch_cost_label)
    end

    it 'returns success false for missing task' do
      result = client.perform_switch(from_task_id: 'ghost', to_task_id: task_b_id, engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:task_not_found)
    end
  end

  describe '#start_training_session' do
    it 'returns success and session_started status' do
      result = client.start_training_session(engine: engine)
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:session_started)
    end
  end

  describe '#end_training_session' do
    it 'returns success after ending an active session' do
      client.start_training_session(engine: engine)
      client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      result = client.end_training_session(engine: engine)
      expect(result[:success]).to be true
      expect(result[:trial_count]).to eq(1)
    end

    it 'returns failure when no active session' do
      result = client.end_training_session(engine: engine)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:no_active_session)
    end
  end

  describe '#average_switch_cost' do
    it 'returns a switch cost with label' do
      client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      result = client.average_switch_cost(engine: engine)
      expect(result[:success]).to be true
      expect(result[:average_switch_cost]).to be_a(Numeric)
      expect(result[:label]).not_to be_nil
    end
  end

  describe '#switch_cost_between' do
    it 'returns cost for a specific task pair' do
      client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      result = client.switch_cost_between(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:average_switch_cost]).to be_a(Numeric)
      expect(result[:from_task_id]).to eq(task_a_id)
      expect(result[:to_task_id]).to eq(task_b_id)
    end
  end

  describe '#flexibility_score' do
    it 'returns score and label' do
      result = client.flexibility_score(engine: engine)
      expect(result[:success]).to be true
      expect(result[:flexibility_score]).to be_between(0.0, 1.0)
      expect(result[:label]).not_to be_nil
    end
  end

  describe '#improvement_rate' do
    it 'returns an improvement_rate value' do
      result = client.improvement_rate(engine: engine)
      expect(result[:success]).to be true
      expect(result[:improvement_rate]).to be_a(Numeric)
    end
  end

  describe '#hardest_switches' do
    it 'returns an array of switch pairs' do
      client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      result = client.hardest_switches(limit: 3, engine: engine)
      expect(result[:success]).to be true
      expect(result[:switches]).to be_an(Array)
      expect(result[:count]).to eq(result[:switches].size)
    end
  end

  describe '#easiest_switches' do
    it 'returns an array of switch pairs' do
      client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      result = client.easiest_switches(limit: 3, engine: engine)
      expect(result[:success]).to be true
      expect(result[:switches]).to be_an(Array)
    end
  end

  describe '#training_report' do
    it 'returns a comprehensive report' do
      client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      result = client.training_report(engine: engine)
      expect(result[:success]).to be true
      expect(result[:report]).to include(:task_count, :trial_count, :flexibility_score, :improvement_rate)
    end
  end

  describe '#list_tasks' do
    it 'returns all registered tasks' do
      task_a_id
      task_b_id
      result = client.list_tasks(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
      expect(result[:tasks]).to be_an(Array)
    end
  end

  describe '#get_task' do
    it 'returns a specific task by id' do
      result = client.get_task(task_id: task_a_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:task][:id]).to eq(task_a_id)
    end

    it 'returns failure for unknown id' do
      result = client.get_task(task_id: 'ghost', engine: engine)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#list_trials' do
    it 'returns all trials' do
      client.perform_switch(from_task_id: task_a_id, to_task_id: task_b_id, engine: engine)
      result = client.list_trials(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:trials]).to be_an(Array)
    end
  end
end
