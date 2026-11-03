require 'rails_helper'

RSpec.describe('broker/broker_carriers/terminals') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }

  before do
    assign(:broker_carrier, broker_carrier)
    stub_template('broker/broker_carriers/_member_header.html.erb' => '', 'terminals/_show_many.html.erb' => 'Account terminals list')
    render
  end

  it { is_expected.to(include('1 Freight Ln, Austin, TX 78744')) }
  it { is_expected.to(include('Account terminals list')) }
end
