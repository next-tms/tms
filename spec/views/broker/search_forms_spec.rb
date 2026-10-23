require 'rails_helper'

RSpec.describe('broker search forms') do
  subject { rendered }

  let(:user) { create(:broker_user) }

  {
    'broker/broker_carriers' => [ BrokerCarrier, '/broker/carriers' ],
    'broker/broker_customers' => [ BrokerCustomer, '/broker/customers' ],
    'broker/contacts' => [ Contact, '/broker/contacts' ],
    'broker/receivables' => [ Receivable, '/broker/receivables' ],
    'broker/shipments' => [ Shipment, '/broker/shipments' ]
  }.each do |path, (model, url)|
    describe "#{path}/_search_form" do
      before do
        without_partial_double_verification do
          allow(view).to(receive_messages(allowed_to?: true, current_user: user, export_filters: {}, export_record_class: model, exportable?: true))
        end

        controller.request.path_parameters.merge!(action: 'index', controller: path)
        render(partial: "#{path}/search_form", locals: { q: model.ransack({}, auth_object: user) })
      end

      it { is_expected.to(include('Filter', 'Export CSV', 'Export YAML')) }
      it { is_expected.to(include("action=\"#{url}.csv\"", "formaction=\"#{url}.yaml\"")) }
    end
  end
end
