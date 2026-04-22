# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::FeedbackListener do
  let(:engine) { Legion::Extensions::Agentic::Executive::GoalManagement::Helpers::GoalEngine.new }
  let(:listener) { described_class.new(engine: engine) }

  describe '#handle_task_event' do
    before do
      result = engine.add_goal(content: 'test goal', domain: :general, priority: 0.5, parent_id: nil, deadline: nil)
      @goal_id = result[:goal][:id]
      goal = engine.goals[@goal_id]
      goal.activate!
      goal.instance_variable_set(:@task_id, 'task-123')
    end

    it 'completes goal on task.completed' do
      result = listener.handle_task_event(task_id: 'task-123', status: 'task.completed')
      expect(result[:found]).to be true
      expect(result[:new_status]).to eq(:completed)
    end

    it 'blocks goal on task.exception' do
      result = listener.handle_task_event(task_id: 'task-123', status: 'task.exception')
      expect(result[:found]).to be true
      expect(result[:new_status]).to eq(:blocked)
    end

    it 'blocks goal on task.failed' do
      result = listener.handle_task_event(task_id: 'task-123', status: 'task.failed')
      expect(result[:found]).to be true
      expect(result[:new_status]).to eq(:blocked)
    end

    it 'returns not found for unknown task_id' do
      result = listener.handle_task_event(task_id: 'unknown', status: 'task.completed')
      expect(result[:found]).to be false
    end

    it 'passes result through on failure status' do
      result = listener.handle_task_event(task_id: 'task-123', status: 'task.failed', result: 'timeout')
      expect(result[:error]).to eq('timeout')
    end
  end

  describe '#start_listening' do
    it 'registers event listeners when Legion::Events is available' do
      events_spy = Class.new do
        attr_reader :registered

        def initialize
          @registered = []
        end

        def on(event, &block)
          @registered << { event: event, block: block }
        end
      end.new
      stub_const('Legion::Events', events_spy)
      listener.start_listening
      event_names = events_spy.registered.map { |r| r[:event] }
      expect(event_names).to include('task.completed')
      expect(event_names).to include('task.failed')
    end

    it 'sets listening? to true after start' do
      events_spy = Class.new do
        def on(_event, &); end
      end.new
      stub_const('Legion::Events', events_spy)
      listener.start_listening
      expect(listener.listening?).to be true
    end

    it 'does not register twice if called again' do
      events_spy = Class.new do
        attr_reader :registered

        def initialize
          @registered = []
        end

        def on(event, &block)
          @registered << { event: event, block: block }
        end
      end.new
      stub_const('Legion::Events', events_spy)
      listener.start_listening
      listener.start_listening
      expect(events_spy.registered.size).to eq(2)
    end

    it 'does nothing when Legion::Events is not defined' do
      hide_const('Legion::Events') if defined?(Legion::Events)
      expect { listener.start_listening }.not_to raise_error
      expect(listener.listening?).to be false
    end
  end

  describe '#listening?' do
    it 'returns false before start_listening' do
      expect(listener.listening?).to be false
    end
  end
end
