# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Volition::Helpers::DriveSynthesizer do
  let(:synth) { described_class }

  describe '.synthesize' do
    it 'returns all five drives' do
      drives = synth.synthesize(tick_results: {}, cognitive_state: {})
      expect(drives).to have_key(:curiosity)
      expect(drives).to have_key(:corrective)
      expect(drives).to have_key(:urgency)
      expect(drives).to have_key(:epistemic)
      expect(drives).to have_key(:social)
    end

    it 'all drives are between 0 and 1' do
      drives = synth.synthesize(
        tick_results:    { emotional_evaluation: { arousal: 0.9 }, gut_instinct: { signal: :alarm } },
        cognitive_state: { curiosity: { intensity: 0.9, active_count: 10 } }
      )
      drives.each_value { |v| expect(v).to be_between(0.0, 1.0) }
    end
  end

  describe '.compute_curiosity_drive' do
    it 'increases with curiosity intensity' do
      low = synth.compute_curiosity_drive({}, { curiosity: { intensity: 0.1, active_count: 0 } })
      high = synth.compute_curiosity_drive({}, { curiosity: { intensity: 0.9, active_count: 5 } })
      expect(high).to be > low
    end
  end

  describe '.compute_corrective_drive' do
    it 'increases with low health and pending adaptations' do
      healthy = synth.compute_corrective_drive({ reflection: { health: 0.95, pending_adaptations: 0 } })
      unhealthy = synth.compute_corrective_drive({ reflection: { health: 0.4, pending_adaptations: 3 } })
      expect(unhealthy).to be > healthy
    end
  end

  describe '.compute_urgency_drive' do
    it 'increases with high arousal and alarm gut signal' do
      calm = synth.compute_urgency_drive({ emotional_evaluation: { arousal: 0.2 }, gut_instinct: { signal: :calm } }, {})
      urgent = synth.compute_urgency_drive({ emotional_evaluation: { arousal: 0.9 }, gut_instinct: { signal: :alarm } }, {})
      expect(urgent).to be > calm
    end
  end

  describe '.compute_epistemic_drive' do
    it 'increases with low prediction confidence' do
      confident = synth.compute_epistemic_drive({ prediction_engine: { confidence: 0.9 } }, {})
      uncertain = synth.compute_epistemic_drive({ prediction_engine: { confidence: 0.2 } }, {})
      expect(uncertain).to be > confident
    end
  end

  describe '.compute_social_drive' do
    it 'increases with peer count and trust' do
      alone = synth.compute_social_drive({ mesh: { peer_count: 0 }, trust: { avg_composite: 0.2 } })
      social = synth.compute_social_drive({ mesh: { peer_count: 5 }, trust: { avg_composite: 0.8 } })
      expect(social).to be > alone
    end
  end

  describe '.dominant_drive' do
    it 'returns the strongest drive' do
      drives = { curiosity: 0.8, corrective: 0.3, urgency: 0.5, epistemic: 0.2, social: 0.1 }
      expect(synth.dominant_drive(drives)).to eq(:curiosity)
    end

    it 'returns nil for empty drives' do
      expect(synth.dominant_drive({})).to be_nil
    end
  end

  describe '.generate_intentions' do
    it 'generates intentions for drives above threshold' do
      drives = { curiosity: 0.8, corrective: 0.05, urgency: 0.6, epistemic: 0.02, social: 0.01 }
      intentions = synth.generate_intentions(drives)
      expect(intentions.size).to eq(2) # curiosity and urgency above 0.15
      expect(intentions.first[:salience]).to be >= intentions.last[:salience]
    end

    it 'returns empty for all drives below threshold' do
      drives = { curiosity: 0.05, corrective: 0.01, urgency: 0.02, epistemic: 0.01, social: 0.01 }
      expect(synth.generate_intentions(drives)).to be_empty
    end
  end

  describe '.extract_gut_strength' do
    it 'maps gut signal symbols to numeric strength' do
      expect(synth.extract_gut_strength({ signal: :alarm })).to eq(1.0)
      expect(synth.extract_gut_strength({ signal: :heightened })).to eq(0.7)
      expect(synth.extract_gut_strength({ signal: :calm })).to eq(0.1)
      expect(synth.extract_gut_strength({ signal: :neutral })).to eq(0.3)
      expect(synth.extract_gut_strength({})).to eq(0.3)
    end
  end
end
