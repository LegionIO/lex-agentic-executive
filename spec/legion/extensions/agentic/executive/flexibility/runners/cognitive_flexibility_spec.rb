# frozen_string_literal: true

require 'legion/extensions/agentic/executive/flexibility/runners/cognitive_flexibility'

RSpec.describe Legion::Extensions::Agentic::Executive::Flexibility::Runners::CognitiveFlexibility do
  let(:eng) { Legion::Extensions::Agentic::Executive::Flexibility::Helpers::FlexibilityEngine.new }
  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@engine, eng)
    obj
  end

  describe '#create_task_set' do
    it 'creates successfully' do
      result = host.create_task_set(name: 'color_sort')
      expect(result[:success]).to be true
    end
  end

  describe '#add_rule' do
    it 'adds a rule to a set' do
      ts = host.create_task_set(name: 'sort')
      result = host.add_rule(set_id: ts[:task_set][:id], type: :if_then, condition: :red, action: :left)
      expect(result[:success]).to be true
    end
  end

  describe '#switch_set' do
    it 'switches task sets' do
      host.create_task_set(name: 'first')
      second = host.create_task_set(name: 'second')
      result = host.switch_set(set_id: second[:task_set][:id])
      expect(result[:success]).to be true
    end
  end

  describe '#current_task_set' do
    it 'returns current set' do
      host.create_task_set(name: 'only')
      result = host.current_task_set
      expect(result[:success]).to be true
      expect(result[:task_set]).not_to be_nil
    end
  end

  describe '#flexibility_level' do
    it 'returns flexibility info' do
      result = host.flexibility_level
      expect(result[:success]).to be true
      expect(result).to include(:flexibility, :label)
    end
  end

  describe '#update_cognitive_flexibility' do
    it 'ticks' do
      result = host.update_cognitive_flexibility
      expect(result[:success]).to be true
    end
  end

  describe '#cognitive_flexibility_stats' do
    it 'returns stats' do
      result = host.cognitive_flexibility_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:set_count)
    end
  end
end
