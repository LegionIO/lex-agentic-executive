# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Autopilot::Runners::CognitiveAutopilot do
  let(:engine) { Legion::Extensions::Agentic::Executive::Autopilot::Helpers::AutopilotEngine.new }
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@default_engine, engine)
    obj
  end

  describe '#register_routine' do
    it 'returns success with routine hash' do
      result = runner.register_routine(pattern: 'check_logs', engine: engine)
      expect(result[:success]).to be true
      expect(result[:routine][:pattern]).to eq('check_logs')
    end
  end

  describe '#execute_routine' do
    it 'returns success with mode and energy' do
      routine = engine.register_routine(pattern: 'test')
      result = runner.execute_routine(routine_id: routine.id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:mode]).to be_a(Symbol)
      expect(result[:energy]).to be_a(Float)
    end

    it 'returns failure for unknown routine' do
      result = runner.execute_routine(routine_id: 'bad', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#switch_to_deliberate' do
    it 'returns success when switching' do
      engine.switch_to_autopilot!
      result = runner.switch_to_deliberate(engine: engine)
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:deliberate)
    end

    it 'returns failure when already deliberate' do
      result = runner.switch_to_deliberate(engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#switch_to_autopilot' do
    it 'returns success' do
      result = runner.switch_to_autopilot(engine: engine)
      expect(result[:success]).to be true
      expect(result[:mode]).to eq(:autopilot)
    end
  end

  describe '#rest' do
    it 'returns success with energy' do
      result = runner.rest(engine: engine)
      expect(result[:success]).to be true
      expect(result[:energy]).to be_a(Float)
    end
  end

  describe '#decay_all' do
    it 'returns success' do
      result = runner.decay_all(engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#autopilot_routines' do
    it 'returns list' do
      engine.register_routine(pattern: 'x', familiarity: 0.9)
      result = runner.autopilot_routines(engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#novel_routines' do
    it 'returns list' do
      engine.register_routine(pattern: 'x', familiarity: 0.1)
      result = runner.novel_routines(engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#get_routine' do
    it 'returns routine by id' do
      routine = engine.register_routine(pattern: 'test')
      result = runner.get_routine(routine_id: routine.id, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown' do
      result = runner.get_routine(routine_id: 'bad', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#autopilot_status' do
    it 'returns comprehensive status' do
      result = runner.autopilot_status(engine: engine)
      expect(result[:success]).to be true
      expect(result[:current_mode]).to eq(:deliberate)
    end
  end
end
