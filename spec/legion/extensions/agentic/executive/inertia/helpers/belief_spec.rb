# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Inertia::Helpers::Belief do
  subject(:belief) { described_class.new(content: 'test belief') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(belief.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets content' do
      expect(belief.content).to eq('test belief')
    end

    it 'defaults to factual domain' do
      expect(belief.domain).to eq(:factual)
    end

    it 'defaults conviction to 0.5' do
      expect(belief.conviction).to eq(0.5)
    end

    it 'starts with default inertia' do
      default = Legion::Extensions::Agentic::Executive::Inertia::Helpers::Constants::DEFAULT_INERTIA
      expect(belief.inertia).to eq(default)
    end

    it 'starts with 0 challenges' do
      expect(belief.challenges_resisted).to eq(0)
      expect(belief.challenges_accepted).to eq(0)
    end

    it 'clamps conviction' do
      high = described_class.new(content: 'h', conviction: 5.0)
      expect(high.conviction).to eq(1.0)
    end
  end

  describe '#challenge!' do
    it 'returns :accepted or :resisted' do
      outcome = belief.challenge!(strength: 0.8)
      expect(%i[accepted resisted]).to include(outcome)
    end

    it 'accepted challenges reduce conviction' do
      original = belief.conviction
      belief.challenge!(strength: 0.9)
      expect(belief.conviction).to be < original if belief.challenges_accepted > 0
    end

    it 'resisted challenges increase inertia' do
      b = described_class.new(content: 'strong', conviction: 0.9)
      original_inertia = b.inertia
      b.challenge!(strength: 0.1)
      expect(b.inertia).to be >= original_inertia
    end

    it 'accepted challenges reduce inertia' do
      original_inertia = belief.inertia
      belief.challenge!(strength: 0.9)
      expect(belief.inertia).to be < original_inertia if belief.challenges_accepted > 0
    end
  end

  describe '#reinforce!' do
    it 'increases conviction' do
      original = belief.conviction
      belief.reinforce!
      expect(belief.conviction).to be > original
    end

    it 'increases inertia' do
      original = belief.inertia
      belief.reinforce!
      expect(belief.inertia).to be > original
    end

    it 'returns self' do
      expect(belief.reinforce!).to eq(belief)
    end
  end

  describe '#entrenched?' do
    it 'is false at default inertia' do
      expect(belief.entrenched?).to be false
    end

    it 'is true at high inertia' do
      10.times { belief.reinforce! }
      expect(belief.entrenched?).to be true
    end
  end

  describe '#flexible?' do
    it 'is false at default inertia' do
      expect(belief.flexible?).to be false
    end
  end

  describe '#resistance_rate' do
    it 'returns 0.0 with no challenges' do
      expect(belief.resistance_rate).to eq(0.0)
    end
  end

  describe '#inertia_label' do
    it 'returns a symbol' do
      expect(belief.inertia_label).to be_a(Symbol)
    end
  end

  describe '#conviction_label' do
    it 'returns a symbol' do
      expect(belief.conviction_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = belief.to_h
      expect(hash).to include(
        :id, :content, :domain, :conviction, :conviction_label,
        :inertia, :inertia_label, :entrenched, :flexible,
        :challenges_resisted, :challenges_accepted, :resistance_rate, :created_at
      )
    end
  end
end
