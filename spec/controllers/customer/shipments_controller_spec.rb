require 'rails_helper'

RSpec.describe(Customer::ShipmentsController) do
  subject { response }

  let(:current_user) { create(:customer_user) }

  before { sign_in(current_user) }

  describe 'GET #index' do
    before { get(:index) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(unknown_includes(Shipment, assigns(:shipments).includes_values)).to(be_empty) }
  end
end
