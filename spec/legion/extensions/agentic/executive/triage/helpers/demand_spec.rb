# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Triage::Helpers::Demand do
  subject(:demand) { described_class.new(description: 'handle urgent request') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(demand.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores description' do
      expect(demand.description).to eq('handle urgent request')
    end

    it 'defaults domain to :general' do
      expect(demand.domain).to eq(:general)
    end

    it 'defaults severity to :moderate' do
      expect(demand.severity).to eq(:moderate)
    end

    it 'defaults urgency to :soon' do
      expect(demand.urgency).to eq(:soon)
    end

    it 'computes triage score from severity and urgency' do
      expect(demand.triage_score).to be_between(0.0, 1.0)
    end

    it 'computes higher score for critical+immediate' do
      critical = described_class.new(description: 'x', severity: :critical, urgency: :immediate)
      trivial = described_class.new(description: 'y', severity: :trivial, urgency: :indefinite)
      expect(critical.triage_score).to be > trivial.triage_score
    end

    it 'defaults to :pending status' do
      expect(demand.status).to eq(:pending)
    end

    it 'falls back to default for invalid severity' do
      bad = described_class.new(description: 'x', severity: :nonexistent)
      expect(bad.severity).to eq(:moderate)
    end

    it 'falls back to default for invalid urgency' do
      bad = described_class.new(description: 'x', urgency: :nonexistent)
      expect(bad.urgency).to eq(:soon)
    end
  end

  describe '#triage!' do
    it 'sets status to :triaged' do
      demand.triage!
      expect(demand.status).to eq(:triaged)
    end

    it 'sets triaged_at' do
      demand.triage!
      expect(demand.triaged_at).to be_a(Time)
    end
  end

  describe '#defer!' do
    it 'sets status to :deferred' do
      demand.defer!
      expect(demand.status).to eq(:deferred)
    end
  end

  describe '#process!' do
    it 'sets status to :processing' do
      demand.process!
      expect(demand.status).to eq(:processing)
    end
  end

  describe '#complete!' do
    it 'sets status to :completed' do
      demand.complete!
      expect(demand.status).to eq(:completed)
    end
  end

  describe '#drop!' do
    it 'sets status to :dropped' do
      demand.drop!
      expect(demand.status).to eq(:dropped)
    end
  end

  describe '#active?' do
    it 'is true when pending' do
      expect(demand.active?).to be true
    end

    it 'is true when triaged' do
      demand.triage!
      expect(demand.active?).to be true
    end

    it 'is false when completed' do
      demand.complete!
      expect(demand.active?).to be false
    end

    it 'is false when dropped' do
      demand.drop!
      expect(demand.active?).to be false
    end
  end

  describe '#red?' do
    it 'is false for moderate severity' do
      expect(demand.red?).to be false
    end

    it 'is true for critical+immediate' do
      red = described_class.new(description: 'x', severity: :critical, urgency: :immediate)
      expect(red.red?).to be true
    end
  end

  describe '#triage_label' do
    it 'returns a symbol' do
      expect(demand.triage_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = demand.to_h
      expect(hash).to include(
        :id, :description, :domain, :severity, :urgency,
        :triage_score, :triage_label, :status, :red, :created_at, :triaged_at
      )
    end
  end
end
