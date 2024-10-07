require 'rails_helper'

RSpec.describe(ContactPolicy) do
  it_behaves_like 'authorized_attributable_policy'
end
