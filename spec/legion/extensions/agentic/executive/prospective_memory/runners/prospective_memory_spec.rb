# frozen_string_literal: true

require 'legion/extensions/agentic/executive/prospective_memory/client'

RSpec.describe Legion::Extensions::Agentic::Executive::ProspectiveMemory::Runners::ProspectiveMemory do
  let(:client) { Legion::Extensions::Agentic::Executive::ProspectiveMemory::Client.new }

  let(:base_params) do
    {
      description:       'review open pull requests',
      trigger_type:      :activity_based,
      trigger_condition: { activity: 'commit_pushed' }
    }
  end

  def create(**overrides)
    client.create_intention(**base_params, **overrides)
  end

  describe '#create_intention' do
    it 'creates an intention and returns a hash with :created true' do
      result = create
      expect(result[:created]).to be true
      expect(result[:intention]).to be_a(Hash)
      expect(result[:intention][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'rejects invalid trigger_type' do
      result = create(trigger_type: :bogus)
      expect(result[:error]).to eq(:invalid_trigger_type)
      expect(result[:valid_types]).to include(:time_based)
    end

    it 'stores urgency on the intention' do
      result = create(urgency: 0.75)
      expect(result[:intention][:urgency]).to eq(0.75)
    end

    it 'stores domain on the intention' do
      result = create(domain: 'engineering')
      expect(result[:intention][:domain]).to eq('engineering')
    end

    it 'sets status to :pending' do
      result = create
      expect(result[:intention][:status]).to eq(:pending)
    end
  end

  describe '#monitor_intention' do
    it 'transitions status to :monitoring' do
      created = create
      result  = client.monitor_intention(intention_id: created[:intention][:id])
      expect(result[:updated]).to be true
      expect(result[:intention][:status]).to eq(:monitoring)
    end

    it 'returns not_found for unknown id' do
      result = client.monitor_intention(intention_id: 'nonexistent')
      expect(result[:updated]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#trigger_intention' do
    it 'transitions status to :triggered' do
      created = create
      result  = client.trigger_intention(intention_id: created[:intention][:id])
      expect(result[:updated]).to be true
      expect(result[:intention][:status]).to eq(:triggered)
    end

    it 'records triggered_at timestamp' do
      created = create
      result  = client.trigger_intention(intention_id: created[:intention][:id])
      expect(result[:intention][:triggered_at]).not_to be_nil
    end
  end

  describe '#execute_intention' do
    it 'transitions status to :executed' do
      created = create
      result  = client.execute_intention(intention_id: created[:intention][:id])
      expect(result[:updated]).to be true
      expect(result[:intention][:status]).to eq(:executed)
    end

    it 'records executed_at timestamp' do
      created = create
      result  = client.execute_intention(intention_id: created[:intention][:id])
      expect(result[:intention][:executed_at]).not_to be_nil
    end

    it 'returns not_found for unknown id' do
      result = client.execute_intention(intention_id: 'nope')
      expect(result[:updated]).to be false
    end
  end

  describe '#cancel_intention' do
    it 'transitions status to :cancelled' do
      created = create
      result  = client.cancel_intention(intention_id: created[:intention][:id])
      expect(result[:updated]).to be true
      expect(result[:intention][:status]).to eq(:cancelled)
    end
  end

  describe '#check_expirations' do
    it 'returns expired_count' do
      client.create_intention(
        description:       'expired',
        trigger_type:      :time_based,
        trigger_condition: {},
        expires_at:        Time.now.utc - 1
      )
      result = client.check_expirations
      expect(result[:expired_count]).to eq(1)
    end
  end

  describe '#pending_intentions' do
    it 'lists pending intentions with count' do
      create
      create
      result = client.pending_intentions
      expect(result[:count]).to eq(2)
      expect(result[:intentions]).to all(include(status: :pending))
    end
  end

  describe '#monitoring_intentions' do
    it 'lists monitoring intentions' do
      created = create
      client.monitor_intention(intention_id: created[:intention][:id])
      result = client.monitoring_intentions
      expect(result[:count]).to eq(1)
      expect(result[:intentions].first[:status]).to eq(:monitoring)
    end
  end

  describe '#triggered_intentions' do
    it 'lists triggered intentions' do
      created = create
      client.trigger_intention(intention_id: created[:intention][:id])
      result = client.triggered_intentions
      expect(result[:count]).to eq(1)
    end
  end

  describe '#intentions_by_domain' do
    it 'filters by domain' do
      create(domain: 'ops')
      create(domain: 'dev')
      result = client.intentions_by_domain(domain: 'ops')
      expect(result[:count]).to eq(1)
      expect(result[:domain]).to eq('ops')
    end
  end

  describe '#intentions_by_urgency' do
    it 'filters by min_urgency' do
      create(urgency: 0.9)
      create(urgency: 0.2)
      result = client.intentions_by_urgency(min_urgency: 0.5)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#most_urgent_intentions' do
    it 'returns sorted by descending urgency' do
      create(urgency: 0.3)
      create(urgency: 0.8)
      result = client.most_urgent_intentions(limit: 5)
      urgencies = result[:intentions].map { |i| i[:urgency] }
      expect(urgencies).to eq(urgencies.sort.reverse)
    end

    it 'respects the limit' do
      3.times { create }
      result = client.most_urgent_intentions(limit: 2)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#decay_urgency' do
    it 'returns decayed: true' do
      create
      result = client.decay_urgency
      expect(result[:decayed]).to be true
    end
  end

  describe '#execution_rate' do
    it 'returns a float execution_rate' do
      result = client.execution_rate
      expect(result[:execution_rate]).to be_a(Float)
    end

    it 'computes rate after executions' do
      c1 = create
      c2 = create
      client.execute_intention(intention_id: c1[:intention][:id])
      client.cancel_intention(intention_id: c2[:intention][:id])
      result = client.execution_rate
      expect(result[:execution_rate]).to be_within(0.001).of(0.5)
    end
  end

  describe '#intention_report' do
    it 'returns total, by_status, execution_rate, most_urgent' do
      create
      report = client.intention_report
      expect(report[:total]).to be >= 1
      expect(report[:by_status]).to be_a(Hash)
      expect(report[:execution_rate]).to be_a(Float)
      expect(report[:most_urgent]).to be_an(Array)
    end
  end
end
