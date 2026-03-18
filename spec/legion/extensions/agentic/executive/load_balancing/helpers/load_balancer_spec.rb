# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::LoadBalancing::Helpers::LoadBalancer do
  subject(:balancer) { described_class.new }

  let(:sub) { balancer.register_subsystem(name: 'reasoning', subsystem_type: :reasoning) }

  describe '#register_subsystem' do
    it 'creates a subsystem' do
      s = balancer.register_subsystem(name: 'memory')
      expect(s.name).to eq('memory')
    end
  end

  describe '#assign_load' do
    it 'assigns load to subsystem' do
      result = balancer.assign_load(subsystem_id: sub.id, amount: 0.3)
      expect(result.current_load).to be_within(0.01).of(0.3)
    end

    it 'returns nil for unknown id' do
      expect(balancer.assign_load(subsystem_id: 'bad', amount: 0.1)).to be_nil
    end
  end

  describe '#shed_load' do
    it 'sheds load from subsystem' do
      balancer.assign_load(subsystem_id: sub.id, amount: 0.5)
      result = balancer.shed_load(subsystem_id: sub.id, amount: 0.2)
      expect(result).to be_within(0.01).of(0.2)
    end
  end

  describe '#auto_assign' do
    it 'assigns to least loaded subsystem' do
      s1 = balancer.register_subsystem(name: 'a')
      s2 = balancer.register_subsystem(name: 'b')
      balancer.assign_load(subsystem_id: s1.id, amount: 0.8)
      result = balancer.auto_assign(amount: 0.1)
      expect(result.id).to eq(s2.id)
    end

    it 'returns nil with no subsystems' do
      expect(balancer.auto_assign(amount: 0.1)).to be_nil
    end
  end

  describe '#rebalance' do
    it 'transfers from overloaded to underloaded' do
      s1 = balancer.register_subsystem(name: 'heavy')
      s2 = balancer.register_subsystem(name: 'light')
      balancer.assign_load(subsystem_id: s1.id, amount: 0.9)
      transfers = balancer.rebalance
      expect(transfers).to be >= 1
      expect(s2.current_load).to be > 0.0
    end
  end

  describe '#overloaded_subsystems' do
    it 'returns only overloaded' do
      balancer.assign_load(subsystem_id: sub.id, amount: 0.9)
      expect(balancer.overloaded_subsystems.size).to eq(1)
    end
  end

  describe '#most_loaded' do
    it 'returns sorted by utilization desc' do
      s1 = balancer.register_subsystem(name: 'a')
      s2 = balancer.register_subsystem(name: 'b')
      balancer.assign_load(subsystem_id: s1.id, amount: 0.3)
      balancer.assign_load(subsystem_id: s2.id, amount: 0.8)
      result = balancer.most_loaded(limit: 2)
      expect(result.first.name).to eq('b')
    end
  end

  describe '#overall_utilization' do
    it 'returns 0.0 with no subsystems' do
      expect(balancer.overall_utilization).to eq(0.0)
    end

    it 'computes average utilization' do
      s1 = balancer.register_subsystem(name: 'a')
      s2 = balancer.register_subsystem(name: 'b')
      balancer.assign_load(subsystem_id: s1.id, amount: 0.4)
      balancer.assign_load(subsystem_id: s2.id, amount: 0.6)
      expect(balancer.overall_utilization).to be_within(0.01).of(0.5)
    end
  end

  describe '#balance_report' do
    it 'returns comprehensive report' do
      sub
      report = balancer.balance_report
      expect(report).to include(:total_subsystems, :overloaded_count,
                                :overall_utilization, :overall_health)
    end
  end

  describe '#to_h' do
    it 'returns engine stats' do
      h = balancer.to_h
      expect(h).to include(:total_subsystems, :overall_utilization, :overall_health)
    end
  end
end
