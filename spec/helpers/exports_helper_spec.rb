require 'rails_helper'

RSpec.describe(ExportsHelper) do
  describe '#export_hidden_fields' do
    subject(:fields) { helper.export_hidden_fields }

    before do
      controller.request.query_parameters.merge!(
        columns: [ 'email' ],
        page: '2',
        q: { first_name_or_last_name_cont: 'Jimmy', s: 'first_name desc' },
      )
    end

    it { is_expected.to(include('<input type="hidden" name="q[first_name_or_last_name_cont]" value="Jimmy"')) }
    it { is_expected.to(include('<input type="hidden" name="q[s]" value="first_name desc"')) }
    it { is_expected.not_to(include('name="columns[]"')) }
    it { is_expected.not_to(include('name="page"')) }

    context 'without query parameters' do
      before { controller.request.query_parameters.clear }

      it { is_expected.to(eq('')) }
    end
  end

  describe '#query_hidden_fields' do
    subject(:fields) { helper.query_hidden_fields(query, namespace) }

    let(:namespace) { nil }
    let(:query) { { 'active' => true, 'status_in' => [ 'booked', 'delivered' ] } }

    it { is_expected.to(include('<input type="hidden" name="active" value="true"')) }
    it { is_expected.to(include('name="status_in[]" value="booked"', 'name="status_in[]" value="delivered"')) }

    context 'with a namespace' do
      let(:namespace) { 'report[filters]' }

      it { is_expected.to(include('name="report[filters][active]" value="true"', 'name="report[filters][status_in][]" value="booked"')) }
    end
  end
end
