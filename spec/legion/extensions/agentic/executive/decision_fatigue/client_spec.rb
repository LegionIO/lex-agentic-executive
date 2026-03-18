# frozen_string_literal: true

require 'legion/extensions/agentic/executive/decision_fatigue/client'

RSpec.describe Legion::Extensions::Agentic::Executive::DecisionFatigue::Client do
  let(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:make_decision)
    expect(client).to respond_to(:fatigue_status)
    expect(client).to respond_to(:rest)
    expect(client).to respond_to(:full_rest)
    expect(client).to respond_to(:recent_decisions)
    expect(client).to respond_to(:decisions_by_type)
    expect(client).to respond_to(:quality_trend)
    expect(client).to respond_to(:should_rest)
  end

  it 'initializes with a fresh fatigue engine' do
    status = client.fatigue_status
    expect(status[:willpower]).to eq(1.0)
    expect(status[:total_decisions]).to eq(0)
  end
end
