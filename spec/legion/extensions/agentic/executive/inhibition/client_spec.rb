# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Executive::Inhibition::Client do
  describe '#initialize' do
    it 'creates default inhibition store' do
      client = described_class.new
      expect(client.inhibition_store).to be_a(Legion::Extensions::Agentic::Executive::Inhibition::Helpers::InhibitionStore)
    end

    it 'accepts injected inhibition store' do
      store  = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::InhibitionStore.new
      client = described_class.new(inhibition_store: store)
      expect(client.inhibition_store).to be(store)
    end

    it 'ignores unknown kwargs' do
      expect { described_class.new(unknown: :value) }.not_to raise_error
    end
  end

  describe 'runner integration' do
    let(:client) { described_class.new }

    it { expect(client).to respond_to(:update_inhibition) }
    it { expect(client).to respond_to(:evaluate_impulse) }
    it { expect(client).to respond_to(:delay_gratification) }
    it { expect(client).to respond_to(:check_stroop) }
    it { expect(client).to respond_to(:willpower_status) }
    it { expect(client).to respond_to(:inhibition_history) }
    it { expect(client).to respond_to(:inhibition_stats) }
  end

  describe 'injected store is used by runner' do
    it 'uses the injected store when evaluating impulses' do
      store  = Legion::Extensions::Agentic::Executive::Inhibition::Helpers::InhibitionStore.new
      client = described_class.new(inhibition_store: store)
      client.evaluate_impulse(action: :act, type: :reactive, strength: :mild)
      expect(store.impulses.size).to eq(1)
    end
  end
end
