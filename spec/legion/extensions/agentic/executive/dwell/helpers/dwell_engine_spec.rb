# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Dwell::Helpers::DwellEngine do
  subject(:engine) { described_class.new }

  let(:problem) { engine.add_topic(content: 'hard bug', topic_type: :problem, salience: 0.8, emotional_intensity: 0.6) }
  let(:idea) { engine.add_topic(content: 'new feature', topic_type: :concept, novelty: 0.9) }

  describe '#add_topic' do
    it 'creates a dwell topic' do
      topic = engine.add_topic(content: 'test')
      expect(topic).to be_a(Legion::Extensions::Agentic::Executive::Dwell::Helpers::DwellTopic)
    end
  end

  describe '#focus_on' do
    it 'engages the topic' do
      original = problem.dwell_level
      engine.focus_on(topic_id: problem.id)
      expect(problem.dwell_level).to be > original
    end

    it 'sets current topic' do
      engine.focus_on(topic_id: problem.id)
      expect(engine.current_topic.id).to eq(problem.id)
    end

    it 'returns nil for unknown topic' do
      expect(engine.focus_on(topic_id: 'bad')).to be_nil
    end
  end

  describe '#disengage' do
    it 'reduces dwell level' do
      engine.focus_on(topic_id: problem.id)
      original = problem.dwell_level
      engine.disengage(topic_id: problem.id)
      expect(problem.dwell_level).to be < original
    end

    it 'clears current topic' do
      engine.focus_on(topic_id: problem.id)
      engine.disengage(topic_id: problem.id)
      expect(engine.current_topic).to be_nil
    end

    it 'returns nil for unknown topic' do
      expect(engine.disengage(topic_id: 'bad')).to be_nil
    end
  end

  describe '#decay_all!' do
    it 'decays all topics' do
      original = problem.dwell_level
      engine.decay_all!
      expect(problem.dwell_level).to be < original
    end
  end

  describe '#current_topic' do
    it 'returns nil initially' do
      expect(engine.current_topic).to be_nil
    end
  end

  describe '#sticky_topics' do
    it 'returns topics with high dwell' do
      high = engine.add_topic(content: 'crisis', salience: 0.9, novelty: 0.9,
                              emotional_intensity: 0.9, complexity: 0.9)
      3.times { engine.focus_on(topic_id: high.id) }
      expect(engine.sticky_topics.map(&:id)).to include(high.id)
    end
  end

  describe '#fleeting_topics' do
    it 'returns heavily decayed topics' do
      topic = engine.add_topic(content: 'minor thing', salience: 0.1, novelty: 0.1,
                               emotional_intensity: 0.0, complexity: 0.1)
      8.times { topic.decay! }
      expect(engine.fleeting_topics.map(&:id)).to include(topic.id)
    end
  end

  describe '#most_engaging' do
    it 'returns topics sorted by dwell level' do
      problem
      idea
      top = engine.most_engaging(limit: 1)
      expect(top.size).to eq(1)
    end
  end

  describe '#hardest_to_disengage' do
    it 'returns topics sorted by difficulty' do
      problem
      idea
      hard = engine.hardest_to_disengage(limit: 1)
      expect(hard.size).to eq(1)
    end
  end

  describe '#average_dwell' do
    it 'returns base with no topics' do
      base = Legion::Extensions::Agentic::Executive::Dwell::Helpers::Constants::BASE_DWELL
      expect(engine.average_dwell).to eq(base)
    end

    it 'computes average' do
      problem
      idea
      expect(engine.average_dwell).to be > 0
    end
  end

  describe '#dwell_report' do
    it 'returns comprehensive report' do
      problem
      report = engine.dwell_report
      expect(report).to include(
        :total_topics, :current_topic, :sticky_count, :fleeting_count,
        :ruminating_count, :average_dwell, :average_disengagement_difficulty,
        :most_engaging
      )
    end
  end

  describe '#to_h' do
    it 'returns summary hash' do
      hash = engine.to_h
      expect(hash).to include(
        :total_topics, :current_topic_id, :sticky_count,
        :ruminating_count, :average_dwell
      )
    end
  end
end
