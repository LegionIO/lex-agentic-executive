# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Control::Client do
  subject(:client) { described_class.new }

  it 'includes the CognitiveControl runner' do
    expect(client).to respond_to(:set_control_goal)
  end

  it 'accepts an injected controller' do
    controller = Legion::Extensions::Agentic::Executive::Control::Helpers::Controller.new
    c = described_class.new(controller: controller)
    expect(c.set_control_goal(description: 'test')[:success]).to be true
  end

  it 'creates goals end-to-end' do
    result = client.set_control_goal(description: 'integration', priority: 0.8)
    expect(result[:success]).to be true

    stats = client.cognitive_control_stats
    expect(stats[:goal_count]).to eq(1)
  end
end
