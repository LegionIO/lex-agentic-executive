# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Autopilot::Client do
  subject(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:register_routine, :execute_routine, :autopilot_status)
  end

  it 'runs a full autopilot lifecycle' do
    reg = client.register_routine(pattern: 'daily_check', domain: :routine, familiarity: 0.65)
    routine_id = reg[:routine][:id]

    # Execute until familiar enough for autopilot
    3.times { client.execute_routine(routine_id: routine_id) }

    status = client.autopilot_status
    expect(status[:success]).to be true
    expect(status[:total_routines]).to eq(1)
  end
end
