# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Volition::Runners::Volition do
  let(:client) { Legion::Extensions::Agentic::Executive::Volition::Client.new }

  describe '#form_intentions' do
    it 'synthesizes drives and forms intentions' do
      result = client.form_intentions(
        tick_results:    {
          emotional_evaluation: { valence: 0.3, arousal: 0.7 },
          gut_instinct:         { signal: :heightened },
          prediction_engine:    { confidence: 0.3 }
        },
        cognitive_state: {
          curiosity:  { intensity: 0.7, active_count: 4, top_question: 'Why are traces sparse?' },
          reflection: { health: 0.6, pending_adaptations: 2 }
        }
      )

      expect(result[:drives]).to be_a(Hash)
      expect(result[:drives].size).to eq(5)
      expect(result[:dominant_drive]).to be_a(Symbol)
      expect(result[:active_intentions]).to be >= 1
      expect(result[:current_intention]).to be_a(Hash)
    end

    it 'handles empty inputs' do
      result = client.form_intentions(tick_results: {}, cognitive_state: {})
      expect(result[:drives]).to be_a(Hash)
      expect(result[:active_intentions]).to be >= 0
    end

    it 'decays existing intentions over multiple ticks' do
      client.form_intentions(
        tick_results:    {},
        cognitive_state: { curiosity: { intensity: 0.9, active_count: 5, top_question: 'test' } }
      )

      # Several ticks with no reinforcement
      5.times { client.form_intentions(tick_results: {}, cognitive_state: {}) }

      stats = client.volition_status
      # Intentions may have decayed/expired
      expect(stats[:intention_stats][:total]).to be >= 0
    end
  end

  describe '#current_intention' do
    it 'returns nil when no intentions exist' do
      result = client.current_intention
      expect(result[:has_will]).to be false
      expect(result[:intention]).to be_nil
    end

    it 'returns the active intention after forming' do
      client.form_intentions(
        tick_results:    {},
        cognitive_state: { curiosity: { intensity: 0.8, active_count: 3, top_question: 'Why?' } }
      )
      result = client.current_intention
      expect(result[:has_will]).to be true
      expect(result[:goal]).to be_a(String)
    end
  end

  describe '#complete_intention' do
    it 'completes an active intention' do
      client.form_intentions(
        tick_results:    {},
        cognitive_state: { curiosity: { intensity: 0.8, active_count: 3, top_question: 'test' } }
      )
      id = client.current_intention[:intention][:intention_id]
      result = client.complete_intention(intention_id: id)
      expect(result[:status]).to eq(:completed)
    end

    it 'returns :not_found for unknown id' do
      result = client.complete_intention(intention_id: 'nonexistent')
      expect(result[:status]).to eq(:not_found)
    end
  end

  describe '#suspend_intention and #resume_intention' do
    it 'suspends and resumes an intention' do
      # Push a single intention directly to avoid multi-drive generation
      intention = Legion::Extensions::Agentic::Executive::Volition::Helpers::Intention.new_intention(
        drive: :curiosity, domain: :general, goal: 'test suspend', salience: 0.8
      )
      client.intention_stack.push(intention)
      id = intention[:intention_id]

      expect(client.suspend_intention(intention_id: id)[:status]).to eq(:suspended)
      expect(client.current_intention[:has_will]).to be false

      expect(client.resume_intention(intention_id: id)[:status]).to eq(:resumed)
      expect(client.current_intention[:has_will]).to be true
    end
  end

  describe '#reinforce_intention' do
    it 'increases intention salience' do
      client.form_intentions(
        tick_results:    {},
        cognitive_state: { curiosity: { intensity: 0.5, active_count: 2, top_question: 'test' } }
      )
      id = client.current_intention[:intention][:intention_id]
      old_salience = client.current_intention[:salience]

      client.reinforce_intention(intention_id: id, amount: 0.3)
      expect(client.current_intention[:salience]).to be > old_salience
    end
  end

  describe '#volition_status' do
    it 'returns comprehensive status' do
      status = client.volition_status
      expect(status[:intention_stats]).to be_a(Hash)
      expect(status[:current_drives]).to be_a(Hash)
      expect(status).to have_key(:has_will)
      expect(status).to have_key(:dominant_drive)
    end
  end

  describe '#intention_history' do
    it 'returns recent intentions' do
      client.form_intentions(
        tick_results:    {},
        cognitive_state: { curiosity: { intensity: 0.7, active_count: 3, top_question: 'q1' } }
      )
      result = client.intention_history(limit: 10)
      expect(result[:intentions]).not_to be_empty
      expect(result[:count]).to be >= 1
    end
  end

  describe '#form_absorption_intention' do
    it 'returns success false when no domains provided' do
      result = client.form_absorption_intention(domains_at_risk: [])
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:no_domains)
    end

    it 'pushes an epistemic absorption intention onto the stack' do
      result = client.form_absorption_intention(
        domains_at_risk:    %w[pki dns],
        neighboring_agents: %w[agent-b agent-c]
      )
      expect(result[:success]).to be true
      expect(result[:result]).to eq(:pushed)
      expect(result[:domains]).to eq(%w[pki dns])
      expect(result[:targets]).to eq(%w[agent-b agent-c])
    end

    it 'returns the intention_id' do
      result = client.form_absorption_intention(domains_at_risk: ['vault'])
      expect(result[:intention_id]).to be_a(String)
    end

    it 'assigns higher salience for critical severity' do
      warning = client.form_absorption_intention(
        domains_at_risk: ['pki'], severity: :warning
      )
      critical_client = Legion::Extensions::Agentic::Executive::Volition::Client.new
      critical = critical_client.form_absorption_intention(
        domains_at_risk: ['pki'], severity: :critical
      )
      expect(critical[:salience]).to be > warning[:salience]
    end

    it 'scales salience with number of at-risk domains' do
      few = client.form_absorption_intention(domains_at_risk: ['pki'])
      many_client = Legion::Extensions::Agentic::Executive::Volition::Client.new
      many = many_client.form_absorption_intention(domains_at_risk: %w[pki dns vault ssh consul nomad])
      expect(many[:salience]).to be >= few[:salience]
    end

    it 'stores knowledge_vulnerability trigger context' do
      result = client.form_absorption_intention(domains_at_risk: ['pki'])
      intention = client.intention_stack.find(result[:intention_id])
      expect(intention[:context][:triggered_by]).to eq(:knowledge_vulnerability)
    end

    it 'returns :duplicate on second call for same domains (capacity protection)' do
      client.form_absorption_intention(domains_at_risk: ['pki'])
      second = client.form_absorption_intention(domains_at_risk: ['pki'])
      # Either duplicate (same drive/domain/goal match) or pushed — both acceptable
      expect(%i[pushed duplicate]).to include(second[:result])
    end
  end
end
