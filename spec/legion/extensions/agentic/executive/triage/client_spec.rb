# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Triage::Client do
  subject(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:add_demand, :process_demand, :complete_demand, :triage_report)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::Agentic::Executive::Triage::Helpers::TriageEngine.new
    custom = described_class.new(engine: engine)
    result = custom.add_demand(description: 'test')
    expect(result[:success]).to be true
  end

  it 'runs a full triage lifecycle' do
    result = client.add_demand(description: 'critical security issue', severity: :critical, urgency: :immediate)
    demand_id = result[:demand][:id]
    expect(result[:demand][:triage_label]).to eq(:red)

    client.process_demand(demand_id: demand_id)
    client.complete_demand(demand_id: demand_id)

    report = client.triage_report
    expect(report[:report][:completed]).to eq(1)
  end
end
