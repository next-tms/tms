require 'rails_helper'

RSpec.describe('broker/broker_carriers/_transponder_terminals') do
  subject { rendered }

  let(:transponder_terminals) { create(:carrier, :saia).transponder_terminals }

  before { render(partial: 'broker/broker_carriers/transponder_terminals', locals: { transponder_terminals: }) }

  it { is_expected.to(include('Shared by FreightKit')) }
  it { is_expected.to(include('1 Freight Ln, Austin, TX 78744')) }
  it { is_expected.to(have_link(href: 'tel:+15125550100')) }

  context 'when there are no shared terminals' do
    let(:transponder_terminals) { [] }

    it { is_expected.to(be_blank) }
  end
end
