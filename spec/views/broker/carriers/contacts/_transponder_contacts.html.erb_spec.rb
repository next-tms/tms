require 'rails_helper'

RSpec.describe('broker/carriers/contacts/_transponder_contacts') do
  subject { rendered }

  let(:transponder_contacts) { create(:carrier, :saia).transponder_contacts }

  before { render(partial: 'broker/carriers/contacts/transponder_contacts', locals: { transponder_contacts: }) }

  it { is_expected.to(include('Shared by FreightKit')) }
  it { is_expected.to(include('Dispatch')) }
  it { is_expected.to(have_link(href: 'tel:+18005551234')) }
  it { is_expected.to(have_link('dispatch@saia.test', href: 'mailto:dispatch@saia.test')) }

  context 'when there are no shared contacts' do
    let(:transponder_contacts) { [] }

    it { is_expected.to(be_blank) }
  end
end
