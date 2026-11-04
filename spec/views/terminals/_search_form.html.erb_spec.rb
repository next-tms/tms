require 'rails_helper'

RSpec.describe('terminals/_search_form') do
  subject { rendered }

  let(:filter) { Broker::Carriers::TerminalsController::FILTER }

  before do
    controller.params[:q] = { filter => 'texas' }
    allow(view).to(receive(:request).and_return(instance_double(ActionDispatch::Request, path: '/broker/carriers/1/terminals')))
    render(partial: 'terminals/search_form', locals: { q: Terminal.ransack(g: [{ m: 'or', filter => 'texas' }]) })
  end

  it { is_expected.to(have_field("q[#{filter}]", with: 'texas')) }
end
