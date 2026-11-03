require 'rails_helper'

RSpec.describe('broker/broker_carriers/contacts') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }

  before do
    assign(:broker_carrier, broker_carrier)
    stub_template('broker/broker_carriers/_member_header.html.erb' => '', 'broker/contacts/_show_many.html.erb' => 'Account contacts list')
    render
  end

  it { is_expected.to(include('dispatch@saia.test')) }
  it { is_expected.to(include('Account contacts list')) }
end
