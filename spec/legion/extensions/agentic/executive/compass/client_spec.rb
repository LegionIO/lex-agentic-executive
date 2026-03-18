# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Executive::Compass::Client do
  subject(:client) { described_class.new }

  it 'includes the runner module' do
    expect(client).to respond_to(:take_bearing)
  end

  it 'includes all runner methods' do
    %i[take_bearing register_bias calibrate
       list_bearings list_biases compass_status].each do |m|
      expect(client).to respond_to(m)
    end
  end
end
