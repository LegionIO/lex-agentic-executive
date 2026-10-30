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

    it 'does not attribute an event without a task ID to an undispatched goal' do
      undispatched = engine.add_goal(content: 'awaiting authorized dispatch')[:goal][:id]
      engine.activate_goal(goal_id: undispatched)

      result = listener.handle_task_event(task_id: nil, status: 'task.completed')

      expect(result).to eq(found: false)
      expect(engine.goal_tree(goal_id: undispatched)[:tree]).to include(status: :active, progress: 0.0)
      expect(engine.goal_tree(goal_id: @goal_id)[:tree]).to include(status: :active, progress: 0.0)
    end

    it 'preserves completion when a delayed failure arrives for the same task' do
      listener.handle_task_event(task_id: 'task-123', status: 'task.completed')

      result = listener.handle_task_event(task_id: 'task-123', status: 'task.failed', result: 'late failure')

      expect(result).to include(new_status: :completed, ignored: :terminal_goal)
      expect(engine.goal_tree(goal_id: @goal_id)[:tree]).to include(status: :completed, progress: 1.0)
    end

    it 'does not credit an abandoned child or its parent for a late completion' do
      parent = engine.add_goal(content: 'parent goal')[:goal][:id]
      engine.activate_goal(goal_id: parent)
      child = engine.add_goal(content: 'cancelled work', parent_id: parent)[:goal][:id]
      engine.activate_goal(goal_id: child)
      engine.assign_task_to_goal(goal_id: child, task_id: 'cancelled-task', runner_mapping: 'TestRunner')
      engine.abandon_goal(goal_id: child)
      before = engine.goal_tree(goal_id: parent)[:tree]

      result = listener.handle_task_event(task_id: 'cancelled-task', status: 'task.completed')

      expect(result).to include(new_status: :abandoned, ignored: :terminal_goal)
      expect(engine.goal_tree(goal_id: parent)[:tree]).to eq(before)
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

  describe '#stop_listening' do
    it 'removes registered handlers and resets listening state' do
      events_spy = Class.new do
        attr_reader :registered, :removed

        def initialize
          @registered = []
          @removed = []
        end

        def on(event, &block)
          @registered << { event: event, block: block }
          block
        end

        def off(event, block)
          @removed << { event: event, block: block }
        end
      end.new
      stub_const('Legion::Events', events_spy)
      listener.start_listening
      expect(listener.listening?).to be true

      listener.stop_listening
      expect(listener.listening?).to be false
      expect(events_spy.removed.size).to eq(2)
      removed_events = events_spy.removed.map { |r| r[:event] }
      expect(removed_events).to include('task.completed')
      expect(removed_events).to include('task.failed')
    end

    it 'does nothing when not listening' do
      expect { listener.stop_listening }.not_to raise_error
      expect(listener.listening?).to be false
    end
  end

  describe '#restart_listening' do
    it 'stops and starts listening' do
      events_spy = Class.new do
        attr_reader :registered, :removed

        def initialize
          @registered = []
          @removed = []
        end

        def on(event, &block)
          @registered << { event: event, block: block }
          block
        end

        def off(event, block)
          @removed << { event: event, block: block }
        end
      end.new
      stub_const('Legion::Events', events_spy)
      listener.start_listening

      listener.restart_listening
      expect(listener.listening?).to be true
      # Original handlers removed, new ones registered
      expect(events_spy.removed.size).to eq(2)
      expect(events_spy.registered.size).to eq(4) # 2 original + 2 new
    end
  end
end
