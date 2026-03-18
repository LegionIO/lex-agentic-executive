# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Inertia::Runners::CognitiveInertia do
  let(:client) { Legion::Extensions::Agentic::Executive::Inertia::Client.new }

  describe '#form_belief' do
    it 'returns success with belief hash' do
      result = client.form_belief(content: 'test')
      expect(result[:success]).to be true
      expect(result[:belief]).to include(:id, :content, :conviction, :inertia)
    end
  end

  describe '#challenge_belief' do
    it 'returns outcome' do
      b = client.form_belief(content: 'test')
      result = client.challenge_belief(belief_id: b[:belief][:id], strength: 0.5)
      expect(result[:success]).to be true
      expect(result[:outcome]).to be_a(Symbol)
    end

    it 'returns failure for unknown id' do
      result = client.challenge_belief(belief_id: 'fake')
      expect(result[:success]).to be false
    end
  end

  describe '#reinforce_belief' do
    it 'returns updated belief' do
      b = client.form_belief(content: 'test')
      result = client.reinforce_belief(belief_id: b[:belief][:id])
      expect(result[:success]).to be true
    end
  end

  describe '#entrenched_beliefs' do
    it 'returns beliefs array' do
      result = client.entrenched_beliefs
      expect(result[:success]).to be true
      expect(result[:beliefs]).to be_a(Array)
    end
  end

  describe '#average_inertia' do
    it 'returns inertia score' do
      result = client.average_inertia
      expect(result[:success]).to be true
      expect(result[:inertia]).to be_a(Numeric)
    end
  end

  describe '#inertia_report' do
    it 'returns a full report' do
      result = client.inertia_report
      expect(result[:success]).to be true
      expect(result[:report]).to include(:total_beliefs, :average_inertia)
    end
  end
end
