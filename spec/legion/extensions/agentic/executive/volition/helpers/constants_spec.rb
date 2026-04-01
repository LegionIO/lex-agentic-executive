# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Executive::Volition::Helpers::Constants do
  describe 'proactive constants' do
    it 'defines PROACTIVE_TRIGGERS' do
      expect(described_class::PROACTIVE_TRIGGERS).to include(:insight, :check_in, :milestone, :curiosity)
    end

    it 'defines PRIORITY_ORDER' do
      expect(described_class::PRIORITY_ORDER).to be_a(Hash)
      expect(described_class::PRIORITY_ORDER[:normal]).to be < described_class::PRIORITY_ORDER[:low]
    end

    it 'defines PROACTIVE_INTENT_TYPE' do
      expect(described_class::PROACTIVE_INTENT_TYPE).to eq(:proactive_outreach)
    end
  end
end
