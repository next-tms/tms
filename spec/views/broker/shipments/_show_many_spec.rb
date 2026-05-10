require 'rails_helper'

RSpec.describe('broker/shipments/_show_many') do
  subject { rendered }

  let(:locals) { { hide_search_form: true, q: nil, shipments: [ shipment ], td_names: %w[status] } }
  let(:shipment) { create(:shipment) }

  before { render(partial: 'broker/shipments/show_many', locals:) }

  it { is_expected.to(include(ShipmentsHelper::TABLE_DATA[:status][:display_name], 'Delivered')) }
end
