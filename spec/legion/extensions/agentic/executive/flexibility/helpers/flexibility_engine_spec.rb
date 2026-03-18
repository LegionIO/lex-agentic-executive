# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Flexibility::Helpers::FlexibilityEngine do
  subject(:engine) { described_class.new }

  let(:constants) { Legion::Extensions::Agentic::Executive::Flexibility::Helpers::Constants }

  describe '#create_task_set' do
    it 'creates a task set' do
      ts = engine.create_task_set(name: 'color_sort')
      expect(ts).to be_a(Legion::Extensions::Agentic::Executive::Flexibility::Helpers::TaskSet)
      expect(engine.task_sets.size).to eq(1)
    end

    it 'sets first as current' do
      ts = engine.create_task_set(name: 'first')
      expect(engine.current_set_id).to eq(ts.id)
    end

    it 'enforces MAX_TASK_SETS' do
      constants::MAX_TASK_SETS.times { |i| engine.create_task_set(name: "set_#{i}") }
      expect(engine.create_task_set(name: 'overflow')).to be_nil
    end
  end

  describe '#switch_to' do
    it 'switches the current set' do
      engine.create_task_set(name: 'first')
      second = engine.create_task_set(name: 'second')
      engine.switch_to(set_id: second.id)
      expect(engine.current_set_id).to eq(second.id)
    end

    it 'returns same set if already current' do
      ts = engine.create_task_set(name: 'only')
      result = engine.switch_to(set_id: ts.id)
      expect(result).to eq(ts)
    end

    it 'incurs switch cost' do
      engine.create_task_set(name: 'first')
      second = engine.create_task_set(name: 'second')
      engine.switch_to(set_id: second.id)
      expect(engine.switch_cost).to eq(constants::SWITCH_COST_BASE)
    end

    it 'records in switch history' do
      engine.create_task_set(name: 'first')
      second = engine.create_task_set(name: 'second')
      engine.switch_to(set_id: second.id)
      expect(engine.switch_history.size).to eq(1)
    end

    it 'returns nil for unknown set' do
      expect(engine.switch_to(set_id: :nope)).to be_nil
    end

    it 'deactivates old and activates new' do
      first = engine.create_task_set(name: 'first')
      second = engine.create_task_set(name: 'second')
      engine.switch_to(set_id: second.id)
      expect(engine.task_sets[first.id].activation).to be < 0.5
      expect(engine.task_sets[second.id].activation).to be > 0.5
    end
  end

  describe '#flexibility' do
    it 'starts at DEFAULT_FLEXIBILITY' do
      expect(engine.flexibility).to eq(constants::DEFAULT_FLEXIBILITY)
    end

    it 'increases with successful switches' do
      engine.create_task_set(name: 'first')
      second = engine.create_task_set(name: 'second')
      before = engine.flexibility
      engine.switch_to(set_id: second.id)
      expect(engine.flexibility).to be > before
    end
  end

  describe '#flexibility_label' do
    it 'returns a symbol' do
      expect(engine.flexibility_label).to be_a(Symbol)
    end
  end

  describe '#perseverating?' do
    it 'returns false initially' do
      expect(engine.perseverating?).to be false
    end
  end

  describe '#available_sets' do
    it 'returns sets other than current' do
      engine.create_task_set(name: 'first')
      engine.create_task_set(name: 'second')
      expect(engine.available_sets.size).to eq(1)
    end
  end

  describe '#tick' do
    it 'decays switch cost' do
      engine.create_task_set(name: 'first')
      second = engine.create_task_set(name: 'second')
      engine.switch_to(set_id: second.id)
      before = engine.switch_cost
      engine.tick
      expect(engine.switch_cost).to be < before
    end
  end

  describe '#to_h' do
    it 'returns summary' do
      h = engine.to_h
      expect(h).to include(:current_set, :set_count, :switch_cost, :flexibility,
                           :label, :perseverating, :switch_count)
    end
  end
end
