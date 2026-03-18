# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Executive::Inhibition::Helpers::Impulse do
  subject(:impulse) do
    described_class.new(type: :reactive, action: :send_message, strength: 0.5)
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(impulse.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns type' do
      expect(impulse.type).to eq(:reactive)
    end

    it 'assigns action' do
      expect(impulse.action).to eq(:send_message)
    end

    it 'assigns strength' do
      expect(impulse.strength).to eq(0.5)
    end

    it 'defaults source to nil' do
      expect(impulse.source).to be_nil
    end

    it 'defaults context to empty hash' do
      expect(impulse.context).to eq({})
    end

    it 'sets created_at' do
      expect(impulse.created_at).to be_a(Time)
    end

    it 'accepts optional source' do
      i = described_class.new(type: :emotional, action: :speak, strength: 0.3, source: :tick)
      expect(i.source).to eq(:tick)
    end

    it 'accepts optional context' do
      i = described_class.new(type: :social, action: :reply, strength: 0.4, context: { trigger: :mention })
      expect(i.context[:trigger]).to eq(:mention)
    end
  end

  describe '#overwhelming?' do
    it 'returns true when strength >= 0.75' do
      i = described_class.new(type: :reactive, action: :act, strength: 0.75)
      expect(i.overwhelming?).to be true
    end

    it 'returns true for 1.0' do
      i = described_class.new(type: :reactive, action: :act, strength: 1.0)
      expect(i.overwhelming?).to be true
    end

    it 'returns false for moderate strength' do
      i = described_class.new(type: :reactive, action: :act, strength: 0.5)
      expect(i.overwhelming?).to be false
    end

    it 'returns false for mild strength' do
      i = described_class.new(type: :reactive, action: :act, strength: 0.25)
      expect(i.overwhelming?).to be false
    end
  end

  describe '#auto_suppressible?' do
    it 'returns true when strength <= 0.2' do
      i = described_class.new(type: :reactive, action: :act, strength: 0.1)
      expect(i.auto_suppressible?).to be true
    end

    it 'returns true at exactly 0.2' do
      i = described_class.new(type: :reactive, action: :act, strength: 0.2)
      expect(i.auto_suppressible?).to be true
    end

    it 'returns false for moderate strength' do
      i = described_class.new(type: :reactive, action: :act, strength: 0.5)
      expect(i.auto_suppressible?).to be false
    end

    it 'returns false for strong strength' do
      i = described_class.new(type: :reactive, action: :act, strength: 0.8)
      expect(i.auto_suppressible?).to be false
    end
  end

  describe 'unique ids' do
    it 'generates different ids for different instances' do
      i1 = described_class.new(type: :reactive, action: :act, strength: 0.5)
      i2 = described_class.new(type: :reactive, action: :act, strength: 0.5)
      expect(i1.id).not_to eq(i2.id)
    end
  end
end
