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

  context "with another customer's shipment" do
    let(:shipment) { create(:shipment) }

    %i[book documents edit quote show unbook].each do |action|
      describe "GET ##{action}" do
        it { expect { get(action, params: { load_id: shipment.load_id }) }.to(raise_error(ActiveRecord::RecordNotFound)) }
      end
    end

    describe 'PATCH #update' do
      it { expect { patch(:update, params: { load_id: shipment.load_id, shipment: { shipper_name: 'Taken' } }) }.to(raise_error(ActiveRecord::RecordNotFound)) }
    end
  end
end
