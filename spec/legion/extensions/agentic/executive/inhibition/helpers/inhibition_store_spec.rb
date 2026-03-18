# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Executive::Inhibition::Helpers::InhibitionStore do
  subject(:store) { described_class.new }

  describe '#initialize' do
    it 'creates an InhibitionModel' do
      expect(store.model).to be_a(Legion::Extensions::Agentic::Executive::Inhibition::Helpers::InhibitionModel)
    end

    it 'starts with empty impulses' do
      expect(store.impulses).to be_empty
    end
  end

  describe '#create_impulse' do
    it 'creates an Impulse instance' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: :moderate)
      expect(impulse).to be_a(Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse)
    end

    it 'resolves symbol strength to float' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: :moderate)
      expect(impulse.strength).to eq(0.5)
    end

    it 'resolves :overwhelming to 1.0' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: :overwhelming)
      expect(impulse.strength).to eq(1.0)
    end

    it 'resolves :negligible to 0.1' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: :negligible)
      expect(impulse.strength).to eq(0.1)
    end

    it 'accepts float strength directly' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: 0.42)
      expect(impulse.strength).to eq(0.42)
    end

    it 'accepts integer strength' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: 1)
      expect(impulse.strength).to eq(1)
    end

    it 'adds impulse to the list' do
      store.create_impulse(type: :reactive, action: :act, strength: :mild)
      expect(store.impulses.size).to eq(1)
    end

    it 'handles unknown symbol strength with fallback' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: :unknown_level)
      expect(impulse.strength).to eq(Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::IMPULSE_STRENGTHS[:moderate])
    end
  end

  describe '#evaluate_and_apply' do
    it 'returns strategy and log_entry' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: :mild)
      result  = store.evaluate_and_apply(impulse)
      expect(result).to include(:strategy, :log_entry)
    end

    it 'returns :auto_suppress for negligible impulse' do
      impulse = store.create_impulse(type: :reactive, action: :act, strength: :negligible)
      result  = store.evaluate_and_apply(impulse)
      expect(result[:strategy]).to eq(:auto_suppress)
    end

    it 'returns a valid strategy' do
      impulse = store.create_impulse(type: :habitual, action: :routine, strength: :moderate)
      result  = store.evaluate_and_apply(impulse)
      valid   = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::INHIBITION_STRATEGIES + %i[auto_suppress failed]
      expect(valid).to include(result[:strategy])
    end
  end

  describe '#recover' do
    it 'recovers willpower on the model' do
      store.model.instance_variable_set(:@willpower, 0.5)
      store.recover
      expect(store.model.willpower).to be > 0.5
    end
  end

  describe '#stats' do
    it 'returns a stats hash with expected keys' do
      result = store.stats
      expect(result).to include(
        :willpower, :willpower_status, :suppressed, :failed,
        :redirected, :success_rate, :log_size, :total_impulses
      )
    end

    it 'reflects impulses created' do
      store.create_impulse(type: :reactive, action: :act, strength: :mild)
      store.create_impulse(type: :social, action: :conform, strength: :moderate)
      expect(store.stats[:total_impulses]).to eq(2)
    end
  end

  describe '#recent_log' do
    it 'returns empty array with no history' do
      expect(store.recent_log).to be_empty
    end

    it 'returns last N entries' do
      5.times do
        imp = store.create_impulse(type: :reactive, action: :act, strength: :mild)
        store.evaluate_and_apply(imp)
      end
      expect(store.recent_log(3).size).to eq(3)
    end

    it 'defaults to 20 entries' do
      25.times do
        imp = store.create_impulse(type: :reactive, action: :act, strength: :mild)
        store.evaluate_and_apply(imp)
      end
      expect(store.recent_log.size).to eq(20)
    end
  end
end
