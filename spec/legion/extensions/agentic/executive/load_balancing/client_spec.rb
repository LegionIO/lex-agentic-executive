# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::LoadBalancing::Client do
  subject(:client) { described_class.new }

  it 'includes the runner module' do
    expect(client).to respond_to(:register_cognitive_subsystem)
  end

  it 'provides an engine' do
    expect(client.engine).to be_a(
      Legion::Extensions::Agentic::Executive::LoadBalancing::Helpers::LoadBalancer
    )
  end

  it 'registers and manages subsystems' do
    result = client.register_cognitive_subsystem(name: 'test')
    expect(result[:success]).to be true
  end
end
