# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Autopilot::Helpers::AutopilotEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts in deliberate mode' do
      expect(engine.current_mode).to eq(:deliberate)
    end

    it 'starts with full energy' do
      expect(engine.energy).to eq(1.0)
    end
  end

  describe '#register_routine' do
    it 'creates a routine' do
      routine = engine.register_routine(pattern: 'check_logs')
      expect(routine.pattern).to eq('check_logs')
    end
  end

  describe '#execute_routine' do
    it 'executes and drains energy' do
      routine = engine.register_routine(pattern: 'test')
      engine.execute_routine(routine_id: routine.id)
      expect(engine.energy).to be < 1.0
    end

    it 'returns nil for unknown routine' do
      expect(engine.execute_routine(routine_id: 'bad')).to be_nil
    end

    it 'auto-switches to autopilot when familiar' do
      routine = engine.register_routine(pattern: 'test', familiarity: 0.65)
      routine.execute!(success: true) # pushes to 0.73 > threshold
      engine.execute_routine(routine_id: routine.id)
      expect(engine.current_mode).to eq(:autopilot)
    end

    it 'auto-switches to deliberate when novel in autopilot mode' do
      # Get into autopilot first
      familiar = engine.register_routine(pattern: 'known', familiarity: 0.8)
      engine.execute_routine(routine_id: familiar.id) # triggers autopilot switch
      expect(engine.current_mode).to eq(:autopilot)

      # Now execute a novel routine
      novel = engine.register_routine(pattern: 'new_thing', familiarity: 0.1)
      engine.execute_routine(routine_id: novel.id)
      expect(engine.current_mode).to eq(:deliberate)
    end
  end

  describe '#switch_to_deliberate!' do
    it 'switches from autopilot to deliberate' do
      engine.switch_to_autopilot!
      result = engine.switch_to_deliberate!
      expect(result).to eq(:deliberate)
    end

    it 'returns nil if already in deliberate' do
      expect(engine.switch_to_deliberate!).to be_nil
    end

    it 'costs energy' do
      engine.switch_to_autopilot!
      before = engine.energy
      engine.switch_to_deliberate!
      expect(engine.energy).to be < before
    end
  end

  describe '#switch_to_autopilot!' do
    it 'switches from deliberate to autopilot' do
      result = engine.switch_to_autopilot!
      expect(result).to eq(:autopilot)
    end

    it 'returns nil if already in autopilot' do
      engine.switch_to_autopilot!
      expect(engine.switch_to_autopilot!).to be_nil
    end
  end

  describe '#rest!' do
    it 'restores energy' do
      engine.switch_to_autopilot!
      engine.switch_to_deliberate! # drains energy
      before = engine.energy
      engine.rest!
      expect(engine.energy).to be > before
    end

    it 'clamps at 1.0' do
      engine.rest!(amount: 5.0)
      expect(engine.energy).to eq(1.0)
    end
  end

  describe '#decay_all!' do
    it 'decays all routines' do
      engine.register_routine(pattern: 'test', familiarity: 0.5)
      result = engine.decay_all!
      expect(result[:routines_decayed]).to eq(1)
    end
  end

  describe '#autopilot_routines' do
    it 'returns routines ready for autopilot' do
      engine.register_routine(pattern: 'expert', familiarity: 0.9)
      engine.register_routine(pattern: 'novice', familiarity: 0.1)
      expect(engine.autopilot_routines.size).to eq(1)
    end
  end

  describe '#novel_routines' do
    it 'returns novel routines' do
      engine.register_routine(pattern: 'new', familiarity: 0.1)
      expect(engine.novel_routines.size).to eq(1)
    end
  end

  describe '#autopilot_ratio' do
    it 'returns 0.0 with no routines' do
      expect(engine.autopilot_ratio).to eq(0.0)
    end

    it 'returns ratio of autopilot-ready routines' do
      engine.register_routine(pattern: 'a', familiarity: 0.9)
      engine.register_routine(pattern: 'b', familiarity: 0.1)
      expect(engine.autopilot_ratio).to eq(0.5)
    end
  end

  describe '#override_count' do
    it 'counts overrides' do
      engine.switch_to_autopilot!
      engine.switch_to_deliberate!
      expect(engine.override_count).to eq(1)
    end
  end

  describe '#exhausted?' do
    it 'is false initially' do
      expect(engine.exhausted?).to be false
    end
  end

  describe '#autopilot_report' do
    it 'includes key fields' do
      report = engine.autopilot_report
      expect(report).to include(
        :current_mode, :energy, :energy_label, :exhausted,
        :total_routines, :autopilot_ready, :novel_count,
        :autopilot_ratio, :mode_label, :total_events, :override_count
      )
    end
  end

  describe '#to_h' do
    it 'includes summary' do
      hash = engine.to_h
      expect(hash).to include(:current_mode, :energy, :total_routines, :autopilot_ratio)
    end
  end
end
