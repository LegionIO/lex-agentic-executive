# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Volition::Client do
  subject(:client) { described_class.new }

  it 'initializes with a default intention stack' do
    expect(client.intention_stack).to be_a(Legion::Extensions::Agentic::Executive::Volition::Helpers::IntentionStack)
  end

  it 'accepts an injected stack' do
    custom = Legion::Extensions::Agentic::Executive::Volition::Helpers::IntentionStack.new
    client = described_class.new(stack: custom)
    expect(client.intention_stack).to be(custom)
  end

  it 'includes the Volition runner' do
    expect(client).to respond_to(:form_intentions)
    expect(client).to respond_to(:current_intention)
    expect(client).to respond_to(:complete_intention)
    expect(client).to respond_to(:suspend_intention)
    expect(client).to respond_to(:resume_intention)
    expect(client).to respond_to(:volition_status)
    expect(client).to respond_to(:intention_history)
  end
end
