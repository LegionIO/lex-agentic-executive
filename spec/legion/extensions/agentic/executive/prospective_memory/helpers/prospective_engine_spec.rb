# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::ProspectiveEngine do
  subject(:engine) { described_class.new }

  let(:basic_params) do
    {
      description:       'check in with team',
      trigger_type:      :event_based,
      trigger_condition: { event: 'sprint_end' },
      domain:            'work'
    }
  end

  def make_intention(**overrides)
    engine.create_intention(**basic_params, **overrides)
  end

  describe '#create_intention' do
    it 'returns an Intention object' do
      expect(make_intention).to be_a(Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::Intention)
    end

    it 'stores the intention' do
      intention = make_intention
      expect(engine.intentions[intention.id]).to eq(intention)
    end

    it 'creates intention with :pending status' do
      expect(make_intention.status).to eq(:pending)
    end

    it 'respects custom urgency' do
      intention = make_intention(urgency: 0.8)
      expect(intention.urgency).to eq(0.8)
    end

    it 'evicts oldest when at capacity' do
      stub_const('Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::Constants::MAX_INTENTIONS', 2)
      first = make_intention
      _second = make_intention
      _third  = make_intention
      expect(engine.intentions.key?(first.id)).to be false
      expect(engine.intentions.size).to eq(2)
    end
  end

  describe '#monitor_intention' do
    it 'sets status to :monitoring' do
      intention = make_intention
      engine.monitor_intention(intention_id: intention.id)
      expect(intention.status).to eq(:monitoring)
    end

    it 'returns nil for unknown id' do
      expect(engine.monitor_intention(intention_id: 'nope')).to be_nil
    end
  end

  describe '#trigger_intention' do
    it 'sets status to :triggered' do
      intention = make_intention
      engine.trigger_intention(intention_id: intention.id)
      expect(intention.status).to eq(:triggered)
    end

    it 'returns nil for unknown id' do
      expect(engine.trigger_intention(intention_id: 'nope')).to be_nil
    end
  end

  describe '#execute_intention' do
    it 'sets status to :executed' do
      intention = make_intention
      engine.execute_intention(intention_id: intention.id)
      expect(intention.status).to eq(:executed)
    end
  end

  describe '#cancel_intention' do
    it 'sets status to :cancelled' do
      intention = make_intention
      engine.cancel_intention(intention_id: intention.id)
      expect(intention.status).to eq(:cancelled)
    end
  end

  describe '#check_expirations' do
    it 'expires overdue pending intentions' do
      expired_intention = make_intention(expires_at: Time.now.utc - 1)
      engine.check_expirations
      expect(expired_intention.status).to eq(:expired)
    end

    it 'expires overdue monitoring intentions' do
      intention = make_intention(expires_at: Time.now.utc - 1)
      engine.monitor_intention(intention_id: intention.id)
      engine.check_expirations
      expect(intention.status).to eq(:expired)
    end

    it 'does not expire future intentions' do
      future = make_intention(expires_at: Time.now.utc + 3600)
      engine.check_expirations
      expect(future.status).to eq(:pending)
    end

    it 'does not expire already-executed intentions' do
      intention = make_intention(expires_at: Time.now.utc - 1)
      engine.execute_intention(intention_id: intention.id)
      engine.check_expirations
      expect(intention.status).to eq(:executed)
    end

    it 'returns the count of expired intentions' do
      make_intention(expires_at: Time.now.utc - 1)
      make_intention(expires_at: Time.now.utc - 1)
      make_intention(expires_at: Time.now.utc + 3600)
      expect(engine.check_expirations).to eq(2)
    end
  end

  describe '#pending_intentions' do
    it 'returns only pending intentions' do
      i1 = make_intention
      i2 = make_intention
      engine.monitor_intention(intention_id: i2.id)
      expect(engine.pending_intentions).to contain_exactly(i1)
    end
  end

  describe '#monitoring_intentions' do
    it 'returns only monitoring intentions' do
      intention = make_intention
      engine.monitor_intention(intention_id: intention.id)
      expect(engine.monitoring_intentions).to contain_exactly(intention)
    end
  end

  describe '#triggered_intentions' do
    it 'returns only triggered intentions' do
      intention = make_intention
      engine.trigger_intention(intention_id: intention.id)
      expect(engine.triggered_intentions).to contain_exactly(intention)
    end
  end

  describe '#by_domain' do
    it 'filters by domain' do
      work_intention = make_intention(domain: 'work')
      make_intention(domain: 'personal')
      results = engine.by_domain(domain: 'work')
      expect(results).to contain_exactly(work_intention)
    end
  end

  describe '#by_urgency' do
    it 'returns intentions at or above min_urgency' do
      high   = make_intention(urgency: 0.8)
      _low   = make_intention(urgency: 0.3)
      result = engine.by_urgency(min_urgency: 0.5)
      expect(result).to contain_exactly(high)
    end
  end

  describe '#most_urgent' do
    it 'returns intentions sorted by descending urgency' do
      i1 = make_intention(urgency: 0.9)
      i2 = make_intention(urgency: 0.4)
      i3 = make_intention(urgency: 0.7)
      result = engine.most_urgent(limit: 3)
      expect(result).to eq([i1, i3, i2])
    end

    it 'excludes executed/expired/cancelled intentions' do
      executed = make_intention(urgency: 0.9)
      active   = make_intention(urgency: 0.5)
      engine.execute_intention(intention_id: executed.id)
      result = engine.most_urgent(limit: 5)
      expect(result).to contain_exactly(active)
    end

    it 'respects the limit parameter' do
      5.times { make_intention }
      expect(engine.most_urgent(limit: 3).size).to eq(3)
    end
  end

  describe '#decay_all_urgency' do
    it 'decreases urgency of pending intentions' do
      intention = make_intention(urgency: 0.5)
      engine.decay_all_urgency
      expect(intention.urgency).to be < 0.5
    end

    it 'decreases urgency of monitoring intentions' do
      intention = make_intention(urgency: 0.5)
      engine.monitor_intention(intention_id: intention.id)
      engine.decay_all_urgency
      expect(intention.urgency).to be < 0.5
    end

    it 'does not decay executed intentions' do
      intention = make_intention(urgency: 0.5)
      engine.execute_intention(intention_id: intention.id)
      engine.decay_all_urgency
      expect(intention.urgency).to eq(0.5)
    end
  end

  describe '#execution_rate' do
    it 'returns 0.0 with no terminal intentions' do
      make_intention
      expect(engine.execution_rate).to eq(0.0)
    end

    it 'computes fraction of executed vs total terminal' do
      i1 = make_intention
      i2 = make_intention
      i3 = make_intention
      engine.execute_intention(intention_id: i1.id)
      engine.execute_intention(intention_id: i2.id)
      engine.cancel_intention(intention_id: i3.id)
      expect(engine.execution_rate).to be_within(0.001).of(2.0 / 3.0)
    end
  end

  describe '#intention_report' do
    it 'returns a hash with total, by_status, execution_rate, most_urgent' do
      make_intention
      report = engine.intention_report
      expect(report[:total]).to eq(1)
      expect(report[:by_status]).to be_a(Hash)
      expect(report[:execution_rate]).to be_a(Float)
      expect(report[:most_urgent]).to be_an(Array)
    end

    it 'includes all status types in by_status' do
      report = engine.intention_report
      Legion::Extensions::Agentic::Executive::ProspectiveMemory::Helpers::Constants::STATUS_TYPES.each do |status|
        expect(report[:by_status]).to have_key(status)
      end
    end
  end

  describe '#to_h' do
    it 'serializes the engine state' do
      make_intention
      h = engine.to_h
      expect(h[:intention_count]).to eq(1)
      expect(h[:intentions]).to be_a(Hash)
      expect(h[:execution_rate]).to be_a(Float)
    end
  end
end
