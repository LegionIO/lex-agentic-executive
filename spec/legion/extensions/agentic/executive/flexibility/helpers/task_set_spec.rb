# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Flexibility::Helpers::TaskSet do
  subject(:ts) { described_class.new(id: :set_one, name: 'sort_by_color', domain: :visual) }

  let(:constants) { Legion::Extensions::Agentic::Executive::Flexibility::Helpers::Constants }

  describe '#initialize' do
    it 'sets id, name, and domain' do
      expect(ts.id).to eq(:set_one)
      expect(ts.name).to eq('sort_by_color')
      expect(ts.domain).to eq(:visual)
    end

    it 'starts at 0.5 activation' do
      expect(ts.activation).to eq(0.5)
    end
  end

  describe '#add_rule' do
    it 'adds a rule' do
      rule = ts.add_rule(type: :if_then, condition: :red, action: :left)
      expect(rule).to be_a(Hash)
      expect(ts.rules.size).to eq(1)
    end

    it 'rejects invalid types' do
      expect(ts.add_rule(type: :bogus, condition: :x, action: :y)).to be_nil
    end

    it 'enforces MAX_RULES_PER_SET' do
      constants::MAX_RULES_PER_SET.times do |i|
        ts.add_rule(type: :if_then, condition: :"c_#{i}", action: :"a_#{i}")
      end
      expect(ts.add_rule(type: :if_then, condition: :overflow, action: :x)).to be_nil
    end
  end

  describe '#activate and #deactivate' do
    it 'increases activation' do
      before = ts.activation
      ts.activate
      expect(ts.activation).to be > before
    end

    it 'decreases activation' do
      ts.activate(0.3)
      before = ts.activation
      ts.deactivate
      expect(ts.activation).to be < before
    end

    it 'increments use count' do
      ts.activate
      expect(ts.use_count).to eq(1)
    end
  end

  describe '#active?' do
    it 'returns true at 0.5' do
      expect(ts.active?).to be true
    end

    it 'returns false below 0.5' do
      ts.activation = 0.3
      expect(ts.active?).to be false
    end
  end

  describe '#dominant?' do
    it 'returns false by default' do
      expect(ts.dominant?).to be false
    end

    it 'returns true above threshold' do
      ts.activation = constants::PERSEVERATION_THRESHOLD + 0.1
      expect(ts.dominant?).to be true
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = ts.to_h
      expect(h).to include(:id, :name, :domain, :activation, :active, :dominant, :rule_count, :use_count)
    end
  end
end
