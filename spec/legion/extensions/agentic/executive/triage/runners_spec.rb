# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Triage::Runners::CognitiveTriage do
  let(:engine) { Legion::Extensions::Agentic::Executive::Triage::Helpers::TriageEngine.new }
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@default_engine, engine)
    obj
  end

  describe '#add_demand' do
    it 'returns success with demand hash' do
      result = runner.add_demand(description: 'urgent fix', severity: :critical, engine: engine)
      expect(result[:success]).to be true
      expect(result[:demand][:severity]).to eq(:critical)
    end

    it 'includes current capacity' do
      result = runner.add_demand(description: 'test', engine: engine)
      expect(result[:capacity]).to be_between(0.0, 1.0)
    end
  end

  describe '#process_demand' do
    it 'returns success for active demand' do
      demand = engine.add_demand(description: 'test')
      result = runner.process_demand(demand_id: demand.id, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown demand' do
      result = runner.process_demand(demand_id: 'bad', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#complete_demand' do
    it 'returns success with capacity' do
      demand = engine.add_demand(description: 'test')
      result = runner.complete_demand(demand_id: demand.id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:capacity]).to be_a(Float)
    end
  end

  describe '#defer_demand' do
    it 'returns success' do
      demand = engine.add_demand(description: 'test')
      result = runner.defer_demand(demand_id: demand.id, engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#drop_demand' do
    it 'returns success' do
      demand = engine.add_demand(description: 'test')
      result = runner.drop_demand(demand_id: demand.id, engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#next_demand' do
    it 'returns found: false when empty' do
      result = runner.next_demand(engine: engine)
      expect(result[:found]).to be false
    end

    it 'returns the highest priority demand' do
      engine.add_demand(description: 'low', severity: :trivial)
      engine.add_demand(description: 'high', severity: :critical, urgency: :immediate)
      result = runner.next_demand(engine: engine)
      expect(result[:found]).to be true
      expect(result[:demand][:severity]).to eq(:critical)
    end
  end

  describe '#active_demands' do
    it 'returns active demands list' do
      engine.add_demand(description: 'test')
      result = runner.active_demands(engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#red_demands' do
    it 'returns red demands' do
      engine.add_demand(description: 'red', severity: :critical, urgency: :immediate)
      result = runner.red_demands(engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#demands_by_severity' do
    it 'filters correctly' do
      engine.add_demand(description: 'a', severity: :critical)
      engine.add_demand(description: 'b', severity: :trivial)
      result = runner.demands_by_severity(severity: :critical, engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#demands_by_domain' do
    it 'filters correctly' do
      engine.add_demand(description: 'a', domain: :security)
      result = runner.demands_by_domain(domain: :security, engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#capacity_status' do
    it 'returns capacity info' do
      result = runner.capacity_status(engine: engine)
      expect(result[:success]).to be true
      expect(result[:capacity]).to eq(1.0)
      expect(result[:overloaded]).to be false
    end
  end

  describe '#triage_report' do
    it 'returns comprehensive report' do
      result = runner.triage_report(engine: engine)
      expect(result[:success]).to be true
      expect(result[:report]).to include(:total_demands, :capacity)
    end
  end
end
