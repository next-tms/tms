require 'rails_helper'

RSpec.describe(Broker::BrokerCustomersController) do
  subject { response }

  let(:broker_customer) { create(:broker_customer, broker: current_user.broker) }
  let(:current_user) { create(:root_broker_user) }

  before do
    sign_in(current_user)
    allow(Accounting).to(receive(:record_class).with(:customer).and_return(double(order: [])))
  end

  describe 'GET #accounting' do
    before { get(:accounting) }

    context 'when accounts receivable' do
      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:customers)).to(eq([])) }
    end

    context 'when not accounts receivable' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when a customer user' do
      let(:current_user) { create(:customer_user).tap { |customer| customer.contact.contact_roles.create!(role: :root) } }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET #index' do
    before do
      broker_customer
      current_user.contact.contact_roles.create!(role: :sales_rep_for_all_broker_customers)
    end

    context 'when format is CSV' do
      before { get(:index, format: :csv) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.content_type).to(start_with('text/csv')) }
      it { expect(response.body).to(include(BrokerCustomer.human_attribute_name(:name))) }
      it { expect(response.body).to(include(broker_customer.name)) }
      it { expect(response.body).to(include(Address.human_attribute_name(:street))) }

      context 'with ransack filter' do
        let(:other_broker_customer) { create(:broker_customer, broker: current_user.broker) }

        before do
          other_broker_customer
          get(:index, format: :csv, params: { q: { customer_name_cont: broker_customer.name } })
        end

        it { expect(response.body).to(include(broker_customer.name)) }
        it { expect(response.body).not_to(include(other_broker_customer.name)) }
      end
    end

    context 'when format is HTML' do
      before { get(:index) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:broker_customers)).to(include(broker_customer)) }
    end
  end

  describe 'PATCH #update_accounting' do
    let(:broker_customer) { create(:broker_customer) }

    before do
      patch(:update_accounting, params: { accounting: { broker_customers: { broker_customer.id => { accounting_customer_id: 'customer-1' } } } })
    end

    it { is_expected.to(redirect_to(accounting_broker_broker_customers_path)) }
    it { expect(broker_customer.reload.accounting_customer_id).to(eq('customer-1')) }
    it { expect(flash[:success]).to(eq('Accounting customers updated')) }
  end
end
