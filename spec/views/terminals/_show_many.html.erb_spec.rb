require 'rails_helper'

RSpec.describe('terminals/_show_many') do
  subject { rendered }

  let(:carrier) { create(:carrier) }
  let(:phone) { '+15125550100' }
  let!(:terminal) { Terminal.create!(address: create(:address, city: 'Austin', region_iso31662: 'US-TX'), carrier:, phone:) }

  before do
    assign(:terminals, Terminal.where(id: terminal.id))
    stub_template('terminals/_search_form.html.erb' => '')
    render(partial: 'terminals/show_many', locals: { q: nil })
  end

  it { is_expected.to(have_link(href: "tel:#{terminal.phone.phony_formatted}")) }

  context 'without a phone' do
    let(:phone) { nil }

    it { is_expected.to(include('Austin')) }
    it { is_expected.not_to(have_link(href: /\Atel:/)) }
  end
end
