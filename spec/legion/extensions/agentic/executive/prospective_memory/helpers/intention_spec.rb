# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::Intention do
  subject(:intention) do
    described_class.new(
      description:       'send follow-up email',
      trigger_type:      :time_based,
      trigger_condition: { at: '2026-04-01T09:00:00Z' },
      urgency:           0.6,
      domain:            'communication'
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(intention.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets status to :pending' do
      expect(intention.status).to eq(:pending)
    end

    it 'clamps urgency to 0.0-1.0' do
      over = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: 1.5)
      expect(over.urgency).to eq(1.0)
    end

    it 'clamps urgency below 0.0' do
      under = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: -0.3)
      expect(under.urgency).to eq(0.0)
    end

    it 'defaults urgency to DEFAULT_URGENCY' do
      default_intention = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {})
      expect(default_intention.urgency).to eq(Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::Constants::DEFAULT_URGENCY)
    end

    it 'sets created_at to a UTC time' do
      expect(intention.created_at).to be_a(Time)
    end

    it 'leaves triggered_at nil initially' do
      expect(intention.triggered_at).to be_nil
    end

    it 'leaves executed_at nil initially' do
      expect(intention.executed_at).to be_nil
    end
  end

  describe '#monitor!' do
    it 'sets status to :monitoring' do
      intention.monitor!
      expect(intention.status).to eq(:monitoring)
    end
  end

  describe '#trigger!' do
    it 'sets status to :triggered' do
      intention.trigger!
      expect(intention.status).to eq(:triggered)
    end

    it 'sets triggered_at' do
      intention.trigger!
      expect(intention.triggered_at).to be_a(Time)
    end
  end

  describe '#execute!' do
    it 'sets status to :executed' do
      intention.execute!
      expect(intention.status).to eq(:executed)
    end

    it 'sets executed_at' do
      intention.execute!
      expect(intention.executed_at).to be_a(Time)
    end
  end

  describe '#expire!' do
    it 'sets status to :expired' do
      intention.expire!
      expect(intention.status).to eq(:expired)
    end
  end

  describe '#cancel!' do
    it 'sets status to :cancelled' do
      intention.cancel!
      expect(intention.status).to eq(:cancelled)
    end
  end

  describe '#expired?' do
    it 'returns false when expires_at is nil' do
      expect(intention.expired?).to be false
    end

    it 'returns false when expires_at is in the future' do
      future = described_class.new(
        description: 'x', trigger_type: :time_based, trigger_condition: {},
        expires_at: Time.now.utc + 3600
      )
      expect(future.expired?).to be false
    end

    it 'returns true when expires_at is in the past' do
      past = described_class.new(
        description: 'x', trigger_type: :time_based, trigger_condition: {},
        expires_at: Time.now.utc - 1
      )
      expect(past.expired?).to be true
    end
  end

  describe '#boost_urgency!' do
    it 'increases urgency by URGENCY_BOOST by default' do
      original = intention.urgency
      intention.boost_urgency!
      expect(intention.urgency).to eq((original + Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::Constants::URGENCY_BOOST).clamp(0.0,
                                                                                                                                                      1.0).round(10))
    end

    it 'accepts a custom amount' do
      intention.boost_urgency!(amount: 0.2)
      expect(intention.urgency).to be > 0.6
    end

    it 'does not exceed 1.0' do
      high = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: 0.95)
      high.boost_urgency!(amount: 0.5)
      expect(high.urgency).to eq(1.0)
    end
  end

  describe '#decay_urgency!' do
    it 'decreases urgency by URGENCY_DECAY' do
      original = intention.urgency
      intention.decay_urgency!
      expect(intention.urgency).to be < original
    end

    it 'does not go below 0.0' do
      low = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: 0.005)
      low.decay_urgency!
      expect(low.urgency).to eq(0.0)
    end

    it 'rounds to 10 decimal places' do
      intention.decay_urgency!
      expect(intention.urgency.to_s.split('.').last.length).to be <= 10
    end
  end

  describe '#urgency_label' do
    it 'returns :critical for urgency >= 0.8' do
      high = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: 0.9)
      expect(high.urgency_label).to eq(:critical)
    end

    it 'returns :high for urgency in 0.6...0.8' do
      expect(intention.urgency_label).to eq(:high)
    end

    it 'returns :moderate for urgency in 0.4...0.6' do
      mid = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: 0.5)
      expect(mid.urgency_label).to eq(:moderate)
    end

    it 'returns :low for urgency in 0.2...0.4' do
      low = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: 0.3)
      expect(low.urgency_label).to eq(:low)
    end

    it 'returns :deferred for urgency < 0.2' do
      very_low = described_class.new(description: 'x', trigger_type: :time_based, trigger_condition: {}, urgency: 0.1)
      expect(very_low.urgency_label).to eq(:deferred)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = intention.to_h
      expect(h[:id]).to eq(intention.id)
      expect(h[:description]).to eq('send follow-up email')
      expect(h[:trigger_type]).to eq(:time_based)
      expect(h[:status]).to eq(:pending)
      expect(h[:domain]).to eq('communication')
      expect(h[:urgency_label]).to eq(:high)
    end
  end
end
