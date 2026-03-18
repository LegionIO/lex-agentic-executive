# frozen_string_literal: true

require 'legion/extensions/agentic/executive/executive_function/client'

RSpec.describe Legion::Extensions::Agentic::Executive::ExecutiveFunction::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    %i[inhibit shift_task update_wm common_ef_status component_status
       can_perform task_switch_cost executive_load
       update_executive_function executive_function_stats].each do |method|
      expect(client).to respond_to(method)
    end
  end

  it 'maintains state across calls' do
    client.inhibit(target: :noise)
    stats = client.executive_function_stats
    expect(stats[:inhibition_count]).to eq(1)
  end

  it 'full round-trip: inhibit -> shift -> update -> stats' do
    client.inhibit(target: :distraction, reason: :prepotent)
    client.shift_task(from: :idle, to: :active)
    client.update_wm(slot: :focus, new_value: :high)

    stats = client.executive_function_stats
    expect(stats[:success]).to be true
    expect(stats[:inhibition_count]).to eq(1)
    expect(stats[:task_history_size]).to eq(1)
    expect(stats[:update_count]).to eq(1)
    expect(stats[:current_task_set]).to eq(:active)
  end

  it 'common EF level decreases under load' do
    initial = client.common_ef_status[:common_ef_level]
    15.times { client.inhibit(target: :x) }
    expect(client.common_ef_status[:common_ef_level]).to be <= initial
  end
end
