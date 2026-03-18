# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Executive::Inhibition::Runners::Inhibition do
  let(:client) { Legion::Extensions::Agentic::Executive::Inhibition::Client.new }

  let(:normal_tick) do
    {
      emotional_evaluation: { arousal: 0.4 },
      conflict:             {},
      prediction_engine:    { error_rate: 0.3 }
    }
  end

  let(:high_arousal_tick) do
    {
      emotional_evaluation: { arousal: 0.95 },
      conflict:             {},
      prediction_engine:    {}
    }
  end

  let(:conflict_tick) do
    {
      emotional_evaluation: {},
      conflict:             { severity: 4 },
      prediction_engine:    {}
    }
  end

  let(:error_tick) do
    {
      emotional_evaluation: {},
      conflict:             {},
      prediction_engine:    { error_rate: 0.9 }
    }
  end

  describe '#update_inhibition' do
    it 'returns a stats hash' do
      result = client.update_inhibition(tick_results: normal_tick)
      expect(result).to include(:willpower, :willpower_status, :suppressed, :failed, :success_rate)
    end

    it 'handles empty tick results' do
      result = client.update_inhibition(tick_results: {})
      expect(result[:willpower]).to be_a(Float)
    end

    it 'recovers willpower each tick' do
      client.inhibition_store.model.instance_variable_set(:@willpower, 0.5)
      client.update_inhibition(tick_results: normal_tick)
      expect(client.inhibition_store.model.willpower).to be > 0.5
    end

    it 'detects emotional impulse from high arousal' do
      client.update_inhibition(tick_results: high_arousal_tick)
      expect(client.inhibition_store.impulses.size).to be >= 1
    end

    it 'detects competitive impulse from high conflict severity' do
      client.update_inhibition(tick_results: conflict_tick)
      competitive = client.inhibition_store.impulses.any? { |i| i.type == :competitive }
      expect(competitive).to be true
    end

    it 'detects reactive impulse from high prediction error' do
      client.update_inhibition(tick_results: error_tick)
      reactive = client.inhibition_store.impulses.any? { |i| i.type == :reactive }
      expect(reactive).to be true
    end

    it 'does not trigger impulses for normal conditions' do
      client.update_inhibition(tick_results: normal_tick)
      expect(client.inhibition_store.impulses).to be_empty
    end
  end

  describe '#evaluate_impulse' do
    it 'returns success for valid type' do
      result = client.evaluate_impulse(action: :send_message, type: :reactive, strength: :moderate)
      expect(result[:success]).to be true
    end

    it 'returns impulse_id' do
      result = client.evaluate_impulse(action: :act, type: :social, strength: :mild)
      expect(result[:impulse_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns strategy' do
      result = client.evaluate_impulse(action: :act, type: :habitual, strength: :moderate)
      expect(result[:strategy]).not_to be_nil
    end

    it 'returns allowed: true when impulse wins (failed strategy)' do
      client.inhibition_store.model.instance_variable_set(:@willpower, 0.1)
      result = client.evaluate_impulse(action: :act, type: :reactive, strength: :moderate)
      expect(result[:allowed]).to be true
    end

    it 'returns allowed: false when impulse is suppressed' do
      result = client.evaluate_impulse(action: :act, type: :reactive, strength: :negligible)
      expect(result[:allowed]).to be false
    end

    it 'returns error for unknown impulse type' do
      result = client.evaluate_impulse(action: :act, type: :unknown_type, strength: :mild)
      expect(result[:success]).to be false
      expect(result[:error]).to include('unknown impulse type')
    end

    it 'accepts string type' do
      result = client.evaluate_impulse(action: :act, type: 'reactive', strength: :mild)
      expect(result[:success]).to be true
    end

    it 'includes strength in result' do
      result = client.evaluate_impulse(action: :act, type: :reactive, strength: :moderate)
      expect(result[:strength]).to eq(0.5)
    end
  end

  describe '#delay_gratification' do
    it 'returns present_value' do
      result = client.delay_gratification(reward: 100, delay: 5)
      expect(result[:present_value]).to be_a(Float)
    end

    it 'returns lower present value for longer delay' do
      short = client.delay_gratification(reward: 100, delay: 2)
      long  = client.delay_gratification(reward: 100, delay: 20)
      expect(long[:present_value]).to be < short[:present_value]
    end

    it 'returns worth_waiting boolean' do
      result = client.delay_gratification(reward: 100, delay: 1)
      expect([true, false]).to include(result[:worth_waiting])
    end

    it 'returns true for small delay' do
      result = client.delay_gratification(reward: 100, delay: 1)
      expect(result[:worth_waiting]).to be true
    end

    it 'returns false for very long delay' do
      result = client.delay_gratification(reward: 100, delay: 100)
      expect(result[:worth_waiting]).to be false
    end

    it 'includes discount rate in result' do
      result = client.delay_gratification(reward: 100, delay: 5)
      expect(result[:discount_rate]).to eq(Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::DELAY_DISCOUNT_RATE)
    end
  end

  describe '#check_stroop' do
    it 'returns conflict boolean' do
      result = client.check_stroop(automatic: :respond, controlled: :respond)
      expect(result[:conflict]).to be false
    end

    it 'detects conflict when responses differ and automatic is strong' do
      auto   = { strength: 0.8 }
      ctrl   = { strength: 0.3 }
      result = client.check_stroop(automatic: auto, controlled: ctrl)
      expect(result[:conflict]).to be true
    end

    it 'includes threshold in result' do
      result = client.check_stroop(automatic: :a, controlled: :b)
      expect(result[:threshold]).to eq(Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::STROOP_CONFLICT_THRESHOLD)
    end

    it 'returns both automatic and controlled in result' do
      result = client.check_stroop(automatic: :a, controlled: :b)
      expect(result).to include(:automatic, :controlled)
    end
  end

  describe '#willpower_status' do
    it 'returns willpower level' do
      result = client.willpower_status
      expect(result[:willpower]).to be_a(Float)
    end

    it 'returns status symbol' do
      result = client.willpower_status
      expect(%i[healthy depleted exhausted]).to include(result[:status])
    end

    it 'returns threshold' do
      result = client.willpower_status
      expect(result[:threshold]).to eq(Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Constants::WILLPOWER_THRESHOLD)
    end

    it 'starts healthy with default willpower' do
      result = client.willpower_status
      expect(result[:status]).to eq(:healthy)
    end
  end

  describe '#inhibition_history' do
    it 'returns log and total' do
      result = client.inhibition_history
      expect(result).to include(:log, :total)
    end

    it 'shows entries after evaluating impulses' do
      client.evaluate_impulse(action: :act, type: :reactive, strength: :moderate)
      result = client.inhibition_history
      expect(result[:total]).to eq(1)
    end
  end

  describe '#inhibition_stats' do
    it 'returns stats hash' do
      stats = client.inhibition_stats
      expect(stats).to include(:willpower, :willpower_status, :suppressed, :failed, :success_rate)
    end

    it 'reflects evaluations performed' do
      client.evaluate_impulse(action: :act, type: :reactive, strength: :mild)
      stats = client.inhibition_stats
      expect(stats[:suppressed]).to be >= 1
    end
  end

  describe 'willpower depletion over many inhibitions' do
    it 'depletes willpower with successive strong impulses' do
      initial = client.inhibition_store.model.willpower
      10.times { client.evaluate_impulse(action: :act, type: :emotional, strength: :strong) }
      expect(client.inhibition_store.model.willpower).to be < initial
    end

    it 'eventually leads to failed inhibition when exhausted' do
      client.inhibition_store.model.instance_variable_set(:@willpower, 0.05)
      result = client.evaluate_impulse(action: :act, type: :reactive, strength: :moderate)
      expect(result[:strategy]).to eq(:failed)
    end
  end
end
