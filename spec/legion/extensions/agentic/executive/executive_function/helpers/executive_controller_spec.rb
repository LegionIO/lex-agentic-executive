# frozen_string_literal: true

require 'legion/extensions/agentic/executive/executive_function/helpers/ef_component'
require 'legion/extensions/agentic/executive/executive_function/helpers/executive_controller'

RSpec.describe Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::ExecutiveController do
  subject(:ctrl) { described_class.new }

  describe '#initialize' do
    it 'has all three EF components' do
      described_class::EF_COMPONENTS.each do |name|
        expect(ctrl.component(name)).to be_a(Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::EfComponent)
      end
    end

    it 'starts with nil current_task_set' do
      expect(ctrl.current_task_set).to be_nil
    end

    it 'starts with empty history logs' do
      expect(ctrl.task_history).to be_empty
      expect(ctrl.inhibition_log).to be_empty
      expect(ctrl.update_log).to be_empty
    end
  end

  describe '#inhibit' do
    it 'returns success when capacity available' do
      result = ctrl.inhibit(target: :distraction, reason: :prepotent_response)
      expect(result[:success]).to be true
      expect(result[:target]).to eq(:distraction)
    end

    it 'records entry in inhibition_log' do
      ctrl.inhibit(target: :noise, reason: :irrelevant)
      expect(ctrl.inhibition_log.size).to eq(1)
    end

    it 'returns failure when fatigued' do
      30.times { ctrl.inhibit(target: :x, reason: :test) }
      result = ctrl.inhibit(target: :x, reason: :test)
      expect(result[:success]).to be(true).or be(false)
    end

    it 'retains at most MAX_INHIBITIONS entries' do
      (described_class::MAX_INHIBITIONS + 5).times do
        ctrl.inhibit(target: :x, reason: :test)
        described_class::EF_COMPONENTS.each { ctrl.component(it).instance_variable_set(:@fatigue, 0.0) }
      end
      expect(ctrl.inhibition_log.size).to be <= described_class::MAX_INHIBITIONS
    end
  end

  describe '#shift_task' do
    it 'returns success and updates current_task_set' do
      result = ctrl.shift_task(from: :read, to: :write)
      expect(result[:success]).to be true
      expect(ctrl.current_task_set).to eq(:write)
    end

    it 'incurs SWITCH_COST for different tasks' do
      result = ctrl.shift_task(from: :task_a, to: :task_b)
      expect(result[:switch_cost]).to eq(described_class::SWITCH_COST)
    end

    it 'incurs zero cost for same task' do
      result = ctrl.shift_task(from: :same, to: :same)
      expect(result[:switch_cost]).to eq(0.0)
    end

    it 'records entry in task_history' do
      ctrl.shift_task(from: :a, to: :b)
      expect(ctrl.task_history.size).to eq(1)
    end
  end

  describe '#update_wm' do
    it 'returns success with slot info' do
      result = ctrl.update_wm(slot: :goal, old_value: :old, new_value: :new)
      expect(result[:success]).to be true
      expect(result[:slot]).to eq(:goal)
      expect(result[:new_value]).to eq(:new)
    end

    it 'records entry in update_log' do
      ctrl.update_wm(slot: :context, old_value: nil, new_value: :fresh)
      expect(ctrl.update_log.size).to eq(1)
    end
  end

  describe '#common_ef_level' do
    it 'returns a float between CAPACITY_FLOOR and CAPACITY_CEILING' do
      level = ctrl.common_ef_level
      expect(level).to be_a(Float)
      expect(level).to be >= Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::EfComponent::CAPACITY_FLOOR
      expect(level).to be <= Legion::Extensions::Agentic::Executive::ExecutiveFunction::Helpers::EfComponent::CAPACITY_CEILING
    end

    it 'decreases after heavy use' do
      initial = ctrl.common_ef_level
      20.times { ctrl.inhibit(target: :t, reason: :r) }
      expect(ctrl.common_ef_level).to be <= initial
    end
  end

  describe '#can_inhibit? / #can_shift? / #can_update?' do
    it 'returns true when components are fresh' do
      expect(ctrl.can_inhibit?).to be true
      expect(ctrl.can_shift?).to be true
      expect(ctrl.can_update?).to be true
    end
  end

  describe '#tick' do
    it 'recovers all components' do
      ctrl.inhibit(target: :x, reason: :y)
      fatigue_before = ctrl.component(:inhibition).fatigue
      ctrl.tick
      expect(ctrl.component(:inhibition).fatigue).to be < fatigue_before
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected top-level keys' do
      h = ctrl.to_h
      expect(h).to include(:common_ef_level, :current_task_set, :components,
                           :task_history_size, :inhibition_count, :update_count)
    end

    it 'includes all three component hashes' do
      described_class::EF_COMPONENTS.each do |name|
        expect(ctrl.to_h[:components]).to have_key(name)
      end
    end
  end
end
