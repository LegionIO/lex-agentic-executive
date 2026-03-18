# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::DissonanceResolution::Runners::CognitiveDissonanceResolution do
  subject(:runner) do
    Class.new do
      include Legion::Extensions::Agentic::Executive::DissonanceResolution::Runners::CognitiveDissonanceResolution

      def engine
        @engine ||= Legion::Extensions::Agentic::Executive::DissonanceResolution::Helpers::ResolutionEngine.new
      end
    end.new
  end

  describe '#create_dissonance_conflict' do
    it 'returns success with conflict data' do
      result = runner.create_dissonance_conflict(belief_a: 'A', belief_b: 'B')
      expect(result[:success]).to be true
      expect(result[:belief_a]).to eq('A')
    end
  end

  describe '#apply_resolution_strategy' do
    it 'applies strategy' do
      created = runner.create_dissonance_conflict(belief_a: 'A', belief_b: 'B')
      result = runner.apply_resolution_strategy(conflict_id: created[:id], strategy: :reframe)
      expect(result[:success]).to be true
    end

    it 'returns error for unknown id' do
      result = runner.apply_resolution_strategy(conflict_id: 'bad', strategy: :reframe)
      expect(result[:success]).to be false
    end
  end

  describe '#dissonance_report' do
    it 'returns report' do
      result = runner.dissonance_report
      expect(result).to include(:total_conflicts, :resolution_rate)
    end
  end

  describe '#update_dissonance_resolution' do
    it 'returns decay stats' do
      result = runner.update_dissonance_resolution
      expect(result[:success]).to be true
      expect(result).to include(:decayed, :stats)
    end
  end
end
