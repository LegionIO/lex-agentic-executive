# frozen_string_literal: true

require 'legion/extensions/agentic/executive/flexibility/client'

RSpec.describe Legion::Extensions::Agentic::Executive::Flexibility::Client do
  subject(:client) { described_class.new }

  it 'creates and switches task sets' do
    client.create_task_set(name: 'color_sort')
    second = client.create_task_set(name: 'shape_sort')
    result = client.switch_set(set_id: second[:task_set][:id])
    expect(result[:success]).to be true
    expect(result[:switch_cost]).to be > 0
  end

  it 'reports flexibility' do
    result = client.flexibility_level
    expect(result[:label]).to be_a(Symbol)
  end
end
