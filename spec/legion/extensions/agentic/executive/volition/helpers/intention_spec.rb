# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Volition::Helpers::Intention do
  let(:helper) { described_class }

  describe '.new_intention' do
    it 'creates an intention with required fields' do
      intention = helper.new_intention(drive: :curiosity, domain: :terraform, goal: 'explore gaps', salience: 0.7)
      expect(intention[:intention_id]).to be_a(String)
      expect(intention[:drive]).to eq(:curiosity)
      expect(intention[:domain]).to eq(:terraform)
      expect(intention[:goal]).to eq('explore gaps')
      expect(intention[:salience]).to eq(0.7)
      expect(intention[:state]).to eq(:active)
      expect(intention[:age_ticks]).to eq(0)
    end

    it 'clamps salience to [0.0, 1.0]' do
      high = helper.new_intention(drive: :urgency, domain: :general, goal: 'respond', salience: 1.5)
      low = helper.new_intention(drive: :urgency, domain: :general, goal: 'respond', salience: -0.5)
      expect(high[:salience]).to eq(1.0)
      expect(low[:salience]).to eq(0.0)
    end
  end

  describe '.decay' do
    it 'reduces salience and increments age' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.5)
      decayed = helper.decay(intention)
      expect(decayed[:salience]).to be < 0.5
      expect(decayed[:age_ticks]).to eq(1)
    end

    it 'floors at 0.0' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.01)
      decayed = helper.decay(intention)
      expect(decayed[:salience]).to eq(0.0)
    end
  end

  describe '.reinforce' do
    it 'increases salience' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.5)
      reinforced = helper.reinforce(intention, amount: 0.2)
      expect(reinforced[:salience]).to eq(0.7)
    end

    it 'caps at 1.0' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.9)
      reinforced = helper.reinforce(intention, amount: 0.5)
      expect(reinforced[:salience]).to eq(1.0)
    end
  end

  describe '.expired?' do
    it 'returns true when salience below floor' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.05)
      expect(helper.expired?(intention)).to be true
    end

    it 'returns true when age exceeds max' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.8)
      intention[:age_ticks] = 101
      expect(helper.expired?(intention)).to be true
    end

    it 'returns false for fresh intention' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.5)
      expect(helper.expired?(intention)).to be false
    end
  end

  describe '.active?' do
    it 'returns true for active non-expired intentions' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.5)
      expect(helper.active?(intention)).to be true
    end

    it 'returns false for completed intentions' do
      intention = helper.new_intention(drive: :curiosity, domain: :general, goal: 'test', salience: 0.5)
      intention[:state] = :completed
      expect(helper.active?(intention)).to be false
    end
  end

  describe '.drive_label' do
    it 'returns human-readable labels' do
      expect(helper.drive_label(:curiosity)).to eq('knowledge seeking')
      expect(helper.drive_label(:corrective)).to eq('self-improvement')
      expect(helper.drive_label(:urgency)).to eq('urgent response')
    end
  end
end
