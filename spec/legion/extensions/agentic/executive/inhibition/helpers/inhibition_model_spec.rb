# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Executive::Inhibition::Helpers::InhibitionModel do
  subject(:model) { described_class.new }

  let(:mild_impulse) do
    Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
      type: :reactive, action: :act, strength: 0.25
    )
  end

  let(:negligible_impulse) do
    Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
      type: :reactive, action: :act, strength: 0.1
    )
  end

  let(:strong_impulse) do
    Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
      type: :emotional, action: :react, strength: 0.8
    )
  end

  describe '#initialize' do
    it 'starts willpower at 0.8' do
      expect(model.willpower).to eq(0.8)
    end

    it 'starts with empty inhibition log' do
      expect(model.inhibition_log).to be_empty
    end

    it 'starts suppressed count at 0' do
      expect(model.suppressed_count).to eq(0)
    end

    it 'starts failed count at 0' do
      expect(model.failed_count).to eq(0)
    end

    it 'starts redirected count at 0' do
      expect(model.redirected_count).to eq(0)
    end
  end

  describe '#evaluate_impulse' do
    it 'returns :auto_suppress for auto-suppressible impulses' do
      expect(model.evaluate_impulse(negligible_impulse)).to eq(:auto_suppress)
    end

    it 'returns :failed when willpower is exhausted' do
      model.instance_variable_set(:@willpower, 0.1)
      expect(model.evaluate_impulse(mild_impulse)).to eq(:failed)
    end

    it 'returns a valid strategy for normal impulses' do
      strategies = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::INHIBITION_STRATEGIES + %i[auto_suppress failed]
      expect(strategies).to include(model.evaluate_impulse(mild_impulse))
    end

    it 'selects :redirect for habitual type' do
      habitual = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
        type: :habitual, action: :routine, strength: 0.5
      )
      expect(model.evaluate_impulse(habitual)).to eq(:redirect)
    end

    it 'selects :delay for overwhelming emotional impulse' do
      overwhelming = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
        type: :emotional, action: :react, strength: 0.9
      )
      expect(model.evaluate_impulse(overwhelming)).to eq(:delay)
    end

    it 'selects :suppression for non-overwhelming emotional impulse' do
      moderate_emotional = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
        type: :emotional, action: :react, strength: 0.4
      )
      expect(model.evaluate_impulse(moderate_emotional)).to eq(:suppression)
    end

    it 'selects :substitute for social impulse' do
      social = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
        type: :social, action: :conform, strength: 0.5
      )
      expect(model.evaluate_impulse(social)).to eq(:substitute)
    end

    it 'selects :defer for competitive impulse' do
      competitive = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
        type: :competitive, action: :escalate, strength: 0.5
      )
      expect(model.evaluate_impulse(competitive)).to eq(:defer)
    end

    it 'selects :suppression for reactive impulse' do
      reactive = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
        type: :reactive, action: :react, strength: 0.5
      )
      expect(model.evaluate_impulse(reactive)).to eq(:suppression)
    end
  end

  describe '#apply_strategy' do
    it 'returns a log entry hash' do
      entry = model.apply_strategy(mild_impulse, :suppression)
      expect(entry).to include(:impulse_id, :type, :action, :strength, :strategy, :willpower, :at)
    end

    it 'increments suppressed_count for suppression' do
      model.apply_strategy(mild_impulse, :suppression)
      expect(model.suppressed_count).to eq(1)
    end

    it 'increments failed_count for failed' do
      model.apply_strategy(mild_impulse, :failed)
      expect(model.failed_count).to eq(1)
    end

    it 'increments both redirected and suppressed for redirect' do
      model.apply_strategy(mild_impulse, :redirect)
      expect(model.redirected_count).to eq(1)
      expect(model.suppressed_count).to eq(1)
    end

    it 'does not deplete willpower for auto_suppress' do
      initial = model.willpower
      model.apply_strategy(negligible_impulse, :auto_suppress)
      expect(model.willpower).to eq(initial)
    end

    it 'depletes willpower for active strategies' do
      initial = model.willpower
      model.apply_strategy(strong_impulse, :suppression)
      expect(model.willpower).to be < initial
    end

    it 'logs the entry' do
      model.apply_strategy(mild_impulse, :suppression)
      expect(model.inhibition_log.size).to eq(1)
    end

    it 'caps the log at MAX_INHIBITION_LOG' do
      max = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::MAX_INHIBITION_LOG
      (max + 10).times do
        imp = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse.new(
          type: :reactive, action: :act, strength: 0.25
        )
        model.apply_strategy(imp, :suppression)
      end
      expect(model.inhibition_log.size).to eq(max)
    end
  end

  describe '#recover_willpower' do
    it 'increases willpower by FATIGUE_RECOVERY_RATE' do
      model.instance_variable_set(:@willpower, 0.5)
      model.recover_willpower
      expect(model.willpower).to be_within(0.001).of(0.52)
    end

    it 'caps at 1.0' do
      model.instance_variable_set(:@willpower, 0.99)
      model.recover_willpower
      expect(model.willpower).to eq(1.0)
    end
  end

  describe '#willpower_status' do
    it 'returns :healthy when willpower >= 0.6' do
      model.instance_variable_set(:@willpower, 0.7)
      expect(model.willpower_status).to eq(:healthy)
    end

    it 'returns :depleted when willpower is between threshold and 0.6' do
      model.instance_variable_set(:@willpower, 0.4)
      expect(model.willpower_status).to eq(:depleted)
    end

    it 'returns :exhausted when willpower is below threshold' do
      model.instance_variable_set(:@willpower, 0.1)
      expect(model.willpower_status).to eq(:exhausted)
    end
  end

  describe '#success_rate' do
    it 'returns 1.0 with no attempts' do
      expect(model.success_rate).to eq(1.0)
    end

    it 'returns ratio of suppressed to total' do
      model.apply_strategy(mild_impulse, :suppression)
      model.apply_strategy(mild_impulse, :failed)
      expect(model.success_rate).to eq(0.5)
    end

    it 'returns 0.0 when all failed' do
      3.times { model.apply_strategy(mild_impulse, :failed) }
      expect(model.success_rate).to eq(0.0)
    end
  end

  describe '#delay_discount' do
    it 'returns full value at zero delay' do
      expect(model.delay_discount(100.0, 0)).to eq(100.0)
    end

    it 'reduces value with delay' do
      discounted = model.delay_discount(100.0, 5)
      expect(discounted).to be < 100.0
    end

    it 'reduces value more with longer delay' do
      short = model.delay_discount(100.0, 5)
      long  = model.delay_discount(100.0, 20)
      expect(long).to be < short
    end

    it 'uses DELAY_DISCOUNT_RATE' do
      rate     = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::DELAY_DISCOUNT_RATE
      expected = 100.0 / (1.0 + (rate * 10))
      expect(model.delay_discount(100.0, 10)).to be_within(0.001).of(expected)
    end
  end

  describe '#stroop_conflict?' do
    it 'returns false when responses match' do
      expect(model.stroop_conflict?(:respond, :respond)).to be false
    end

    it 'returns true when responses differ and automatic is strong' do
      automatic  = { strength: 0.8 }
      controlled = { strength: 0.4 }
      expect(model.stroop_conflict?(automatic, controlled)).to be true
    end

    it 'returns false when automatic strength is below threshold' do
      automatic  = { strength: 0.3 }
      controlled = { strength: 0.7 }
      expect(model.stroop_conflict?(automatic, controlled)).to be false
    end
  end
end
