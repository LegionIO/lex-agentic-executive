# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::TrainingTask do
  subject(:task) { described_class.new(name: 'Number Sorting', domain: :numerical, difficulty: 0.5) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(task.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores the name' do
      expect(task.name).to eq('Number Sorting')
    end

    it 'stores the domain' do
      expect(task.domain).to eq(:numerical)
    end

    it 'clamps difficulty to [0, 1]' do
      over  = described_class.new(name: 'x', domain: :logical, difficulty: 1.5)
      under = described_class.new(name: 'y', domain: :logical, difficulty: -0.1)
      expect(over.difficulty).to eq(1.0)
      expect(under.difficulty).to eq(0.0)
    end

    it 'sets baseline_performance inversely to difficulty' do
      easy = described_class.new(name: 'easy', domain: :logical, difficulty: 0.0)
      hard = described_class.new(name: 'hard', domain: :logical, difficulty: 1.0)
      expect(easy.baseline_performance).to be > hard.baseline_performance
    end

    it 'initializes practice_count to 0' do
      expect(task.practice_count).to eq(0)
    end

    it 'sets created_at' do
      expect(task.created_at).to be_a(Time)
    end
  end

  describe '#practice!' do
    it 'increments practice_count' do
      task.practice!
      expect(task.practice_count).to eq(1)
    end

    it 'improves baseline_performance' do
      before = task.baseline_performance
      task.practice!
      expect(task.baseline_performance).to be > before
    end

    it 'returns self for chaining' do
      expect(task.practice!).to be(task)
    end

    it 'does not exceed 1.0 with many practices' do
      50.times { task.practice! }
      expect(task.baseline_performance).to be <= 1.0
    end

    it 'exhibits diminishing returns' do
      improvements = []
      prev = task.baseline_performance
      5.times do
        task.practice!
        improvements << (task.baseline_performance - prev)
        prev = task.baseline_performance
      end
      expect(improvements.first).to be >= improvements.last
    end
  end

  describe '#difficulty_label' do
    it 'returns :trivial for difficulty 0.0' do
      easy_task = described_class.new(name: 'x', domain: :logical, difficulty: 0.0)
      expect(easy_task.difficulty_label).to eq(:trivial)
    end

    it 'returns :extreme for difficulty 1.0' do
      hard_task = described_class.new(name: 'x', domain: :logical, difficulty: 1.0)
      expect(hard_task.difficulty_label).to eq(:extreme)
    end

    it 'returns a symbol from DIFFICULTY_LEVELS' do
      expect(Legion::Extensions::Agentic::Executive::FlexibilityTraining::Helpers::Constants::DIFFICULTY_LEVELS).to include(task.difficulty_label)
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      h = task.to_h
      expect(h).to include(:id, :name, :domain, :difficulty, :baseline_performance,
                           :practice_count, :difficulty_label, :created_at)
    end
  end
end
