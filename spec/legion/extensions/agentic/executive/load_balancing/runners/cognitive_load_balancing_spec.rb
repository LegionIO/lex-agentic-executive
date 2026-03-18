# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::LoadBalancing::Runners::CognitiveLoadBalancing do
  subject(:runner) do
    Class.new do
      include Legion::Extensions::Agentic::Executive::LoadBalancing::Runners::CognitiveLoadBalancing

      def engine
        @engine ||= Legion::Extensions::Agentic::Executive::LoadBalancing::Helpers::LoadBalancer.new
      end
    end.new
  end

  describe '#register_cognitive_subsystem' do
    it 'returns success' do
      result = runner.register_cognitive_subsystem(name: 'attention')
      expect(result[:success]).to be true
      expect(result[:name]).to eq('attention')
    end
  end

  describe '#assign_cognitive_load' do
    it 'assigns load' do
      created = runner.register_cognitive_subsystem(name: 'x')
      result = runner.assign_cognitive_load(subsystem_id: created[:id], amount: 0.3)
      expect(result[:success]).to be true
    end
  end

  describe '#auto_assign_load' do
    it 'auto-assigns to least loaded' do
      runner.register_cognitive_subsystem(name: 'a')
      result = runner.auto_assign_load(amount: 0.2)
      expect(result[:success]).to be true
    end
  end

  describe '#rebalance_cognitive_load' do
    it 'returns transfer stats' do
      result = runner.rebalance_cognitive_load
      expect(result[:success]).to be true
      expect(result).to include(:transfers, :stats)
    end
  end

  describe '#cognitive_load_balancing_stats' do
    it 'returns stats' do
      result = runner.cognitive_load_balancing_stats
      expect(result).to include(:total_subsystems, :overall_utilization)
    end
  end
end
