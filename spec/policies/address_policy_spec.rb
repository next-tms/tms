require 'rails_helper'

RSpec.describe(AddressPolicy) do
  it_behaves_like 'authorized_attributable_policy'
end
