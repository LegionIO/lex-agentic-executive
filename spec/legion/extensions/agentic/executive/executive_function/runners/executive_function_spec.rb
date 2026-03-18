# frozen_string_literal: true

require 'legion/extensions/agentic/executive/executive_function/client'

RSpec.describe Legion::Extensions::Agentic::Executive::ExecutiveFunction::Runners::ExecutiveFunction do
  subject(:runner) { Legion::Extensions::Agentic::Executive::ExecutiveFunction::Client.new }

  describe '#inhibit' do
    it 'returns success: true' do
      result = runner.inhibit(target: :noise)
      expect(result[:success]).to be true
    end

    it 'returns the suppressed target' do
      result = runner.inhibit(target: :distraction, reason: :irrelevant)
      expect(result[:target]).to eq(:distraction)
    end

    it 'includes remaining_capacity' do
      result = runner.inhibit(target: :x)
      expect(result[:remaining_capacity]).to be_a(Float)
    end
  end

  describe '#shift_task' do
    it 'returns success: true' do
      result = runner.shift_task(from: :task_a, to: :task_b)
      expect(result[:success]).to be true
    end

    it 'returns from and to task names' do
      result = runner.shift_task(from: :reading, to: :writing)
      expect(result[:to]).to eq(:writing)
    end

    it 'returns switch_cost' do
      result = runner.shift_task(from: :a, to: :b)
      expect(result[:switch_cost]).to be_a(Float)
    end
  end

  describe '#update_wm' do
    it 'returns success: true' do
      result = runner.update_wm(slot: :goal, new_value: :complete)
      expect(result[:success]).to be true
    end

    it 'echoes slot and new_value' do
      result = runner.update_wm(slot: :context, old_value: :stale, new_value: :fresh)
      expect(result[:slot]).to eq(:context)
      expect(result[:new_value]).to eq(:fresh)
    end
  end

  describe '#common_ef_status' do
    it 'returns success: true' do
      result = runner.common_ef_status
      expect(result[:success]).to be true
    end

    it 'includes common_ef_level' do
      result = runner.common_ef_status
      expect(result[:common_ef_level]).to be_a(Float)
    end

    it 'includes all three components' do
      result = runner.common_ef_status
      Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::ExecutiveController::EF_COMPONENTS.each do |name|
        expect(result[:components]).to have_key(name)
      end
    end
  end

  describe '#component_status' do
    it 'returns success: true for known component' do
      result = runner.component_status(component: :inhibition)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown component' do
      result = runner.component_status(component: :nonexistent)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:unknown_component)
    end

    it 'includes component hash' do
      result = runner.component_status(component: :shifting)
      expect(result[:component]).to include(:name, :capacity, :effective_capacity)
    end
  end

  describe '#can_perform' do
    it 'returns success: true for :inhibit' do
      result = runner.can_perform(operation: :inhibit)
      expect(result[:success]).to be true
      expect(result[:can_perform]).to be true
    end

    it 'returns success: true for :shift' do
      result = runner.can_perform(operation: :shift)
      expect(result[:success]).to be true
      expect(result[:can_perform]).to be true
    end

    it 'returns success: true for :update' do
      result = runner.can_perform(operation: :update)
      expect(result[:can_perform]).to be true
    end

    it 'handles unknown operation gracefully' do
      result = runner.can_perform(operation: :fly)
      expect(result[:can_perform]).to be false
      expect(result[:reason]).to eq(:unknown_operation)
    end
  end

  describe '#task_switch_cost' do
    it 'returns SWITCH_COST for different tasks' do
      result = runner.task_switch_cost(from: :a, to: :b)
      expect(result[:switch_cost]).to eq(
        Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::ExecutiveController::SWITCH_COST
      )
    end

    it 'returns zero for same task' do
      result = runner.task_switch_cost(from: :same, to: :same)
      expect(result[:switch_cost]).to eq(0.0)
    end

    it 'includes shifting_capacity' do
      result = runner.task_switch_cost(from: :a, to: :b)
      expect(result[:shifting_capacity]).to be_a(Float)
    end
  end

  describe '#executive_load' do
    it 'returns success: true' do
      result = runner.executive_load
      expect(result[:success]).to be true
    end

    it 'returns executive_load as float' do
      result = runner.executive_load
      expect(result[:executive_load]).to be_a(Float)
    end

    it 'load increases after heavy use' do
      initial = runner.executive_load[:executive_load]
      10.times { runner.inhibit(target: :x) }
      expect(runner.executive_load[:executive_load]).to be >= initial
    end
  end

  describe '#update_executive_function' do
    it 'updates component capacity' do
      result = runner.update_executive_function(component: :inhibition, capacity: 0.9)
      expect(result[:success]).to be true
      expect(result[:new_capacity]).to be_within(0.001).of(0.9)
    end

    it 'clamps capacity to CAPACITY_FLOOR' do
      result = runner.update_executive_function(component: :shifting, capacity: -1.0)
      expect(result[:new_capacity]).to be >=
                                       Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::EfComponent::CAPACITY_FLOOR
    end

    it 'returns failure for unknown component' do
      result = runner.update_executive_function(component: :bogus, capacity: 0.5)
      expect(result[:success]).to be false
    end
  end

  describe '#executive_function_stats' do
    it 'returns success: true' do
      result = runner.executive_function_stats
      expect(result[:success]).to be true
    end

    it 'includes common_ef_level' do
      result = runner.executive_function_stats
      expect(result[:common_ef_level]).to be_a(Float)
    end

    it 'includes all three components' do
      result = runner.executive_function_stats
      Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::ExecutiveController::EF_COMPONENTS.each do |name|
        expect(result[:components]).to have_key(name)
      end
    end
  end
end
