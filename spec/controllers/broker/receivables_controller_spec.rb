require 'rails_helper'

RSpec.describe(Broker::ReceivablesController) do
  subject { response }

  let(:user) { create(:root_broker_user) }

  before { sign_in(user) }

  describe 'GET #index' do
    context 'when CSV' do
      before { get(:index, format: :csv) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.media_type).to(eq('text/csv')) }
      it { expect(CSV.parse(response.body).first).to(eq(ExporterService.new(Receivable.none, authorizable: user).headers)) }
    end

    context 'when YAML' do
      before { get(:index, format: :yaml) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.media_type).to(eq('application/x-yaml')) }
    end

    context 'when sorted by total' do
      let!(:receivables) do
        [ 200, 100 ].map { |total_cents| create(:receivable, shipment: create(:shipment), total_cents:) }
      end

      before { get(:index, params: { q: { s: 'total_cents asc' } }) }

      it { expect(assigns(:receivables)).to(eq(receivables.reverse)) }
    end
  end
end
