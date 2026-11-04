require 'rails_helper'

RSpec.describe('broker/carriers/contacts/index') do
  subject { rendered }

  let(:carrier) { create(:carrier, :saia) }

  before do
    assign(:carrier, carrier)
    stub_template('broker/carriers/_member_header.html.erb' => '', 'broker/contacts/_show_many.html.erb' => 'Local contacts list')
    render
  end

  it { is_expected.to(include('dispatch@saia.test')) }
  it { is_expected.to(include('Local contacts list')) }
end
