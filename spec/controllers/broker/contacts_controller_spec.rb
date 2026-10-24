require 'rails_helper'

RSpec.describe(Broker::ContactsController) do
  subject { response }

  let(:contact) { create(:contact, companyable: nil) }
  let(:user) { create(:root_broker_user) }

  before do
    contact
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when HTML' do
      before { get(:index) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:contacts).first.association(:user)).to(be_loaded) }
    end

    context 'when CSV' do
      before { get(:index, format: :csv) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.media_type).to(eq('text/csv')) }
      it { expect(CSV.parse(response.body).first).to(eq(ExporterService.new(Contact.none, authorizable: user).headers)) }
      it { expect(response.body).to(include(contact.email)) }
    end

    context 'when YAML' do
      before { get(:index, format: :yaml) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.media_type).to(eq('application/x-yaml')) }
    end
  end
end
