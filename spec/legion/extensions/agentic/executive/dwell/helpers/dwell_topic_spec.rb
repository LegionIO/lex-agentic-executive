# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Dwell::Helpers::DwellTopic do
  subject(:topic) { described_class.new(content: 'test problem') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(topic.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets content' do
      expect(topic.content).to eq('test problem')
    end

    it 'defaults to concept type' do
      expect(topic.topic_type).to eq(:concept)
    end

    it 'computes initial dwell from weighted factors' do
      expect(topic.dwell_level).to be > 0.0
      expect(topic.dwell_level).to be <= 1.0
    end

    it 'high inputs produce higher dwell' do
      high = described_class.new(content: 'x', salience: 0.9, novelty: 0.9,
                                 emotional_intensity: 0.9, complexity: 0.9)
      expect(high.dwell_level).to be > topic.dwell_level
    end

    it 'clamps values' do
      high = described_class.new(content: 'x', salience: 5.0)
      expect(high.salience).to eq(1.0)
    end
  end

  describe '#engage!' do
    it 'increases dwell level' do
      original = topic.dwell_level
      topic.engage!
      expect(topic.dwell_level).to be > original
    end

    it 'increments engagement count' do
      topic.engage!
      expect(topic.engagement_count).to eq(1)
    end

    it 'clamps at 1.0' do
      15.times { topic.engage! }
      expect(topic.dwell_level).to eq(1.0)
    end
  end

  describe '#decay!' do
    it 'reduces dwell level' do
      original = topic.dwell_level
      topic.decay!
      expect(topic.dwell_level).to be < original
    end

    it 'reduces novelty' do
      original = topic.novelty
      topic.decay!
      expect(topic.novelty).to be < original
    end
  end

  describe '#disengage!' do
    it 'reduces dwell level' do
      original = topic.dwell_level
      topic.disengage!
      expect(topic.dwell_level).to be < original
    end

    it 'reduces more with force' do
      t1 = described_class.new(content: 'a', salience: 0.8, emotional_intensity: 0.8)
      t2 = described_class.new(content: 'b', salience: 0.8, emotional_intensity: 0.8)
      t1.disengage!(force: 0.0)
      t2.disengage!(force: 0.5)
      expect(t2.dwell_level).to be < t1.dwell_level
    end
  end

  describe '#sticky?' do
    it 'is false for low-input topic' do
      low = described_class.new(content: 'x', salience: 0.1, novelty: 0.1,
                                emotional_intensity: 0.0, complexity: 0.1)
      expect(low.sticky?).to be false
    end

    it 'is true for high-input topic' do
      high = described_class.new(content: 'x', salience: 0.9, novelty: 0.9,
                                 emotional_intensity: 0.9, complexity: 0.9)
      expect(high.sticky?).to be true
    end
  end

  describe '#fleeting?' do
    it 'is false at moderate levels' do
      expect(topic.fleeting?).to be false
    end

    it 'is true after heavy decay on low topic' do
      low = described_class.new(content: 'x', salience: 0.1, novelty: 0.1,
                                emotional_intensity: 0.0, complexity: 0.1)
      5.times { low.decay! }
      expect(low.fleeting?).to be true
    end
  end

  describe '#ruminating?' do
    it 'is false normally' do
      expect(topic.ruminating?).to be false
    end
  end

  describe '#disengagement_difficulty' do
    it 'returns a value between 0 and 1' do
      expect(topic.disengagement_difficulty).to be_between(0.0, 1.0)
    end

    it 'is higher with high emotion' do
      emotional = described_class.new(content: 'x', emotional_intensity: 0.9)
      calm = described_class.new(content: 'y', emotional_intensity: 0.1)
      expect(emotional.disengagement_difficulty).to be > calm.disengagement_difficulty
    end
  end

  describe '#dwell_label' do
    it 'returns a symbol' do
      expect(topic.dwell_label).to be_a(Symbol)
    end
  end

  describe '#engagement_label' do
    it 'returns a symbol' do
      expect(topic.engagement_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = topic.to_h
      expect(hash).to include(
        :id, :content, :topic_type, :salience, :novelty,
        :emotional_intensity, :complexity, :dwell_level, :dwell_label,
        :sticky, :fleeting, :ruminating, :disengagement_difficulty,
        :disengage_label, :engagement_count, :engagement_label, :created_at
      )
    end
  end
end
