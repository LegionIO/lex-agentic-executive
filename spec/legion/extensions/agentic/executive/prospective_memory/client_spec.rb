# frozen_string_literal: true

require 'legion/extensions/agentic/executive/prospective_memory/client'

RSpec.describe Legion::Extensions::Agentic::Executive::ProspectiveMemory::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:create_intention)
    expect(client).to respond_to(:monitor_intention)
    expect(client).to respond_to(:trigger_intention)
    expect(client).to respond_to(:execute_intention)
    expect(client).to respond_to(:cancel_intention)
    expect(client).to respond_to(:check_expirations)
    expect(client).to respond_to(:pending_intentions)
    expect(client).to respond_to(:monitoring_intentions)
    expect(client).to respond_to(:triggered_intentions)
    expect(client).to respond_to(:intentions_by_domain)
    expect(client).to respond_to(:intentions_by_urgency)
    expect(client).to respond_to(:most_urgent_intentions)
    expect(client).to respond_to(:decay_urgency)
    expect(client).to respond_to(:execution_rate)
    expect(client).to respond_to(:intention_report)
  end
end
