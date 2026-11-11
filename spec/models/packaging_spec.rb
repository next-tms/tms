require 'rails_helper'

RSpec.describe(Packaging) { describe('relationships') { it { is_expected.to(have_many(:items).dependent(:restrict_with_error)) } } }
