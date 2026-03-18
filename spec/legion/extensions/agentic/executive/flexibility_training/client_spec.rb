# frozen_string_literal: true

require 'legion/extensions/agentic/executive/flexibility_training/client'

RSpec.describe Legion::Extensions::Agentic::Executive::FlexibilityTraining::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:register_task)
    expect(client).to respond_to(:perform_switch)
    expect(client).to respond_to(:start_training_session)
    expect(client).to respond_to(:end_training_session)
    expect(client).to respond_to(:average_switch_cost)
    expect(client).to respond_to(:switch_cost_between)
    expect(client).to respond_to(:flexibility_score)
    expect(client).to respond_to(:improvement_rate)
    expect(client).to respond_to(:hardest_switches)
    expect(client).to respond_to(:easiest_switches)
    expect(client).to respond_to(:training_report)
    expect(client).to respond_to(:list_tasks)
    expect(client).to respond_to(:get_task)
    expect(client).to respond_to(:list_trials)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::FlexibilityEngine.new
    client = described_class.new(engine: engine)
    result = client.register_task(name: 'Test', domain: :logical, difficulty: 0.5, engine: engine)
    expect(result[:success]).to be true
    expect(engine.tasks.size).to eq(1)
  end

  it 'creates its own engine when none injected' do
    client1 = described_class.new
    client2 = described_class.new
    client1.register_task(name: 'T1', domain: :logical, difficulty: 0.2)
    result = client2.list_tasks
    expect(result[:count]).to eq(0)
  end
end
