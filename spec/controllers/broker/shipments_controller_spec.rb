require 'rails_helper'

RSpec.describe(Broker::ShipmentsController) do
  subject { response }

  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:shipment) { create(:shipment, broker: current_user.companyable) }

  before { sign_in(current_user) }

  describe 'GET #history' do
    let!(:item) { create(:item, shipment:) }

    before { get(:history, params: { load_id: shipment.load_id }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:audits)).to(include(*shipment.audits)) }
    it { expect(assigns(:audits)).to(include(*item.audits)) }
    it { expect(assigns(:audits).map(&:created_at)).to(eq(assigns(:audits).map(&:created_at).sort.reverse)) }
  end
end
