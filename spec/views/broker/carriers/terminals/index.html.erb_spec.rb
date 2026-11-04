require 'rails_helper'

RSpec.describe('broker/carriers/terminals/index') do
  subject { rendered }

  let(:carrier) { create(:carrier, :saia) }

  before do
    assign(:carrier, carrier)
    stub_template('broker/carriers/_member_header.html.erb' => '', 'terminals/_show_many.html.erb' => 'Local terminals list')
    render
  end

  it { is_expected.to(include('1 Freight Ln, Austin, TX 78744')) }
  it { is_expected.to(include('Local terminals list')) }
end
