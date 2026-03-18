# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::CognitiveDebt do
  it 'has a version number' do
    expect(Legion::Extensions::Agentic::Executive::CognitiveDebt::VERSION).not_to be_nil
  end

  it 'has a version that is a string' do
    expect(Legion::Extensions::Agentic::Executive::CognitiveDebt::VERSION).to be_a(String)
  end

  it 'has the correct version format' do
    expect(Legion::Extensions::Agentic::Executive::CognitiveDebt::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
