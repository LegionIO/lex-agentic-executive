# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::DissonanceResolution::Client do
  subject(:client) { described_class.new }

  it 'includes the runner module' do
    expect(client).to respond_to(:create_dissonance_conflict)
  end

  it 'provides an engine' do
    expect(client.engine).to be_a(
      Legion::Extensions::Agentic::Executive::DissonanceResolution::Helpers::ResolutionEngine
    )
  end

  it 'creates and resolves conflicts' do
    result = client.create_dissonance_conflict(belief_a: 'X', belief_b: 'Y')
    expect(result[:success]).to be true
  end
end
