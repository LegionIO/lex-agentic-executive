# frozen_string_literal: true

require 'legion/extensions/agentic/executive/goal_management/helpers/constants'
require 'legion/extensions/agentic/executive/goal_management/helpers/goal'
require 'legion/extensions/agentic/executive/goal_management/helpers/task_dispatcher'

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::TaskDispatcher do
  subject(:dispatcher) { described_class.new }

  let(:goal_hash) do
    {
      id:      'goal-123',
      content: 'ensure safety monitors are healthy',
      domain:  :safety,
      status:  :active
    }
  end

  let(:unknown_domain_goal) do
    { id: 'goal-999', content: 'do something', domain: :unknown_domain, status: :active }
  end

  let(:nil_domain_goal) do
    { id: 'goal-nil', content: 'no domain', domain: nil, status: :active }
  end

  describe '#dispatch_goal' do
    context 'when the domain has no runner mapping' do
      it 'returns dispatched: false with reason :no_runner' do
        result = dispatcher.dispatch_goal(goal: unknown_domain_goal)
        expect(result[:dispatched]).to be false
        expect(result[:reason]).to eq(:no_runner)
      end

      it 'includes the domain in the response' do
        result = dispatcher.dispatch_goal(goal: unknown_domain_goal)
        expect(result[:domain]).to eq(:unknown_domain)
      end

      it 'includes goal_id in the response' do
        result = dispatcher.dispatch_goal(goal: unknown_domain_goal)
        expect(result[:goal_id]).to eq('goal-999')
      end
    end

    context 'when domain is nil' do
      it 'returns dispatched: false' do
        result = dispatcher.dispatch_goal(goal: nil_domain_goal)
        expect(result[:dispatched]).to be false
      end
    end

    context 'when the runner class is not loaded' do
      it 'returns dispatched: false' do
        result = dispatcher.dispatch_goal(goal: goal_hash)
        expect(result[:dispatched]).to be false
      end
    end

    context 'when Legion::Runner is available' do
      before do
        stub_const('Legion::Runner', Class.new do
          def self.run(**_opts)
            { success: true, status: 'task.completed', task_id: 'task-abc', result: {} }
          end
        end)

        stub_const('Legion::Extensions::MindGrowth::Runners::Monitor', Module.new)
      end

      it 'dispatches a leaf goal and returns task_id' do
        result = dispatcher.dispatch_goal(goal: goal_hash)
        expect(result[:success]).to be true
        expect(result[:task_id]).to eq('task-abc')
        expect(result[:dispatched]).to be true
      end

      it 'includes runner_mapping in the response' do
        result = dispatcher.dispatch_goal(goal: goal_hash)
        expect(result[:runner_mapping]).to eq('Legion::Extensions::MindGrowth::Runners::Monitor')
      end

      it 'includes goal_id in the response' do
        result = dispatcher.dispatch_goal(goal: goal_hash)
        expect(result[:goal_id]).to eq('goal-123')
      end

      it 'sets success: false when runner does not return task.completed status' do
        stub_const('Legion::Runner', Class.new do
          def self.run(**_opts)
            { success: false, status: 'task.failed', task_id: nil, result: {} }
          end
        end)

        result = dispatcher.dispatch_goal(goal: goal_hash)
        expect(result[:dispatched]).to be true
        expect(result[:success]).to be false
      end
    end

    context 'when a client_class domain is used (introspection)' do
      let(:introspection_goal) do
        { id: 'goal-456', content: 'check volition', domain: :introspection, status: :active }
      end

      context 'when client class is not available' do
        before do
          hide_const('Legion::Extensions::Agentic::Executive::Volition::Client')
        end

        it 'returns dispatched: false' do
          result = dispatcher.dispatch_goal(goal: introspection_goal)
          expect(result[:dispatched]).to be false
        end
      end

      context 'when client class is available' do
        before do
          client_double = instance_double('VolitionClient',
                                          volition_status: { status: 'task.completed', task_id: 'task-xyz' })
          client_class  = class_double('Legion::Extensions::Agentic::Executive::Volition::Client',
                                       new: client_double)
          stub_const('Legion::Extensions::Agentic::Executive::Volition::Client', client_class)
        end

        it 'dispatches via client and returns dispatched: true' do
          result = dispatcher.dispatch_goal(goal: introspection_goal)
          expect(result[:dispatched]).to be true
          expect(result[:task_id]).to eq('task-xyz')
        end
      end
    end
  end

  describe 'DOMAIN_RUNNERS constant' do
    it 'defines a safety mapping' do
      expect(described_class::DOMAIN_RUNNERS).to have_key(:safety)
    end

    it 'defines a cognition mapping' do
      expect(described_class::DOMAIN_RUNNERS).to have_key(:cognition)
    end

    it 'defines a perception mapping' do
      expect(described_class::DOMAIN_RUNNERS).to have_key(:perception)
    end

    it 'defines an introspection mapping' do
      expect(described_class::DOMAIN_RUNNERS).to have_key(:introspection)
    end

    it 'is frozen' do
      expect(described_class::DOMAIN_RUNNERS).to be_frozen
    end

    it 'safety mapping has a runner_class' do
      expect(described_class::DOMAIN_RUNNERS[:safety]).to have_key(:runner_class)
    end

    it 'introspection mapping has a client_class' do
      expect(described_class::DOMAIN_RUNNERS[:introspection]).to have_key(:client_class)
    end

    it 'all mappings have a function' do
      described_class::DOMAIN_RUNNERS.each_value do |mapping|
        expect(mapping).to have_key(:function)
      end
    end

    it 'all mappings have an args_builder callable' do
      described_class::DOMAIN_RUNNERS.each_value do |mapping|
        expect(mapping[:args_builder]).to respond_to(:call)
      end
    end
  end
end
