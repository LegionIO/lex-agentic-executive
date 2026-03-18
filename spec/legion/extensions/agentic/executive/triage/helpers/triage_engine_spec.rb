# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Triage::Helpers::TriageEngine do
  subject(:engine) { described_class.new }

  describe '#add_demand' do
    it 'creates and returns a triaged demand' do
      demand = engine.add_demand(description: 'test task')
      expect(demand.status).to eq(:triaged)
    end

    it 'drains capacity' do
      engine.add_demand(description: 'test', severity: :critical, urgency: :immediate)
      expect(engine.capacity).to be < 1.0
    end
  end

  describe '#process_demand' do
    it 'sets demand to processing' do
      demand = engine.add_demand(description: 'test')
      engine.process_demand(demand_id: demand.id)
      expect(demand.status).to eq(:processing)
    end

    it 'returns nil for unknown demand' do
      expect(engine.process_demand(demand_id: 'nonexistent')).to be_nil
    end

    it 'returns nil for completed demand' do
      demand = engine.add_demand(description: 'test')
      demand.complete!
      expect(engine.process_demand(demand_id: demand.id)).to be_nil
    end
  end

  describe '#complete_demand' do
    it 'completes the demand' do
      demand = engine.add_demand(description: 'test')
      engine.complete_demand(demand_id: demand.id)
      expect(demand.status).to eq(:completed)
    end

    it 'restores some capacity' do
      demand = engine.add_demand(description: 'test', severity: :critical)
      capacity_before = engine.capacity
      engine.complete_demand(demand_id: demand.id)
      expect(engine.capacity).to be > capacity_before
    end

    it 'returns nil for unknown demand' do
      expect(engine.complete_demand(demand_id: 'bad')).to be_nil
    end
  end

  describe '#defer_demand' do
    it 'defers the demand' do
      demand = engine.add_demand(description: 'test')
      engine.defer_demand(demand_id: demand.id)
      expect(demand.status).to eq(:deferred)
    end

    it 'partially restores capacity' do
      demand = engine.add_demand(description: 'test', severity: :critical)
      before = engine.capacity
      engine.defer_demand(demand_id: demand.id)
      expect(engine.capacity).to be > before
    end
  end

  describe '#drop_demand' do
    it 'drops the demand' do
      demand = engine.add_demand(description: 'test')
      engine.drop_demand(demand_id: demand.id)
      expect(demand.status).to eq(:dropped)
    end

    it 'restores capacity' do
      demand = engine.add_demand(description: 'test', severity: :critical)
      before = engine.capacity
      engine.drop_demand(demand_id: demand.id)
      expect(engine.capacity).to be > before
    end
  end

  describe '#next_demand' do
    it 'returns nil when no active demands' do
      expect(engine.next_demand).to be_nil
    end

    it 'returns highest triage score demand' do
      engine.add_demand(description: 'low', severity: :trivial, urgency: :indefinite)
      high = engine.add_demand(description: 'high', severity: :critical, urgency: :immediate)
      expect(engine.next_demand.id).to eq(high.id)
    end
  end

  describe '#active_demands' do
    it 'returns only active demands' do
      d1 = engine.add_demand(description: 'a')
      engine.add_demand(description: 'b')
      d1.complete!
      expect(engine.active_demands.size).to eq(1)
    end
  end

  describe '#red_demands' do
    it 'returns critical+immediate demands' do
      engine.add_demand(description: 'red', severity: :critical, urgency: :immediate)
      engine.add_demand(description: 'green', severity: :trivial, urgency: :indefinite)
      expect(engine.red_demands.size).to eq(1)
    end
  end

  describe '#demands_by_severity' do
    it 'filters by severity' do
      engine.add_demand(description: 'a', severity: :critical)
      engine.add_demand(description: 'b', severity: :trivial)
      expect(engine.demands_by_severity(severity: :critical).size).to eq(1)
    end
  end

  describe '#demands_by_domain' do
    it 'filters by domain' do
      engine.add_demand(description: 'a', domain: :security)
      engine.add_demand(description: 'b', domain: :memory)
      expect(engine.demands_by_domain(domain: :security).size).to eq(1)
    end
  end

  describe '#overloaded?' do
    it 'is false initially' do
      expect(engine.overloaded?).to be false
    end

    it 'is true after many critical demands' do
      20.times { engine.add_demand(description: 'x', severity: :critical, urgency: :immediate) }
      expect(engine.overloaded?).to be true
    end
  end

  describe '#queue_pressure' do
    it 'is 0.0 with no demands' do
      expect(engine.queue_pressure).to eq(0.0)
    end

    it 'increases with active demands' do
      5.times { engine.add_demand(description: 'x') }
      expect(engine.queue_pressure).to be > 0.0
    end
  end

  describe '#restore_capacity!' do
    it 'increases capacity' do
      engine.add_demand(description: 'drain', severity: :critical)
      before = engine.capacity
      engine.restore_capacity!
      expect(engine.capacity).to be > before
    end

    it 'clamps at 1.0' do
      10.times { engine.restore_capacity!(0.2) }
      expect(engine.capacity).to eq(1.0)
    end
  end

  describe '#triage_report' do
    it 'includes key report fields' do
      report = engine.triage_report
      expect(report).to include(
        :total_demands, :active_count, :red_count, :completed, :dropped,
        :deferred, :capacity, :capacity_label, :overloaded, :queue_pressure,
        :queue_label, :next_demand
      )
    end
  end

  describe '#to_h' do
    it 'includes summary counts' do
      hash = engine.to_h
      expect(hash).to include(:total_demands, :active, :capacity, :overloaded)
    end
  end
end
