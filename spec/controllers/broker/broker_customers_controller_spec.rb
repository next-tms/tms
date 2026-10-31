require 'rails_helper'

RSpec.describe(Broker::BrokerCustomersController) do
  let(:current_user) { create(:root_broker_user) }

  before do
    sign_in(current_user)
    allow(Accounting).to(receive(:record_class).with(:customer).and_return(double(order: [])))
  end

  describe '#accounting_params' do
    subject { controller.__send__(:accounting_params).to_h }

    let(:attributes) { { '1' => { accounting_customer_id: '2' } } }

    before { controller.params = { accounting: { broker_customers: attributes } } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end

  describe '#broker_customer_params' do
    subject { controller.__send__(:broker_customer_params).to_h }

    let(:attributes) do
      {
        broker_customer_sales_reps_attributes: { '0' => { user_id: '3' } },
        can_quote: '1',
        receivables_contact_attributes: { contact_attributes: { email: 'ap@example.com' } }
      }
    end

    before { controller.params = { broker_customer: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
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

  describe 'PATCH #update_accounting' do
    let(:broker_customer) { create(:broker_customer) }

    before do
      patch(:update_accounting,
            params: { accounting: { broker_customers: { broker_customer.id => { accounting_customer_id: 'customer-1' } } } })
    end

    it { is_expected.to(redirect_to(accounting_broker_broker_customers_path)) }
    it { expect(broker_customer.reload.accounting_customer_id).to(eq('customer-1')) }
    it { expect(flash[:success]).to(eq('Accounting customers updated')) }
  end
end
