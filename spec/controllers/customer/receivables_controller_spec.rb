require 'rails_helper'

RSpec.describe(Customer::ReceivablesController) do
  subject { response }

  let(:query) { { s: 'total_cents asc' } }
  let(:user) { create(:customer_user).tap { |user| user.add_role(:accounts_payable) } }

  let!(:receivables) do
    [ 200, 100 ].map { |total_cents| create(:receivable, shipment: create(:shipment, broker_customer: user.companyable), total_cents:) }
  end

  before { sign_in(user) }

  describe 'GET #index' do
    before { get(:index, params: { q: query }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:receivables)).to(eq(receivables.reverse)) }

    context 'with a search' do
      let(:predicate) { :authorized_by_first_name_or_authorized_by_last_name_or_shipment_broker_customer_customer_name_or_shipment_load_id_cont }
      let(:query) { { predicate => receivables.first.shipment.load_id } }

      it { expect(assigns(:receivables)).to(eq([ receivables.first ])) }
    end
  end

  describe 'GET #paid' do
    before { get(:paid, params: { q: query }) }

    it { is_expected.to(have_http_status(:ok)) }
  end
end
