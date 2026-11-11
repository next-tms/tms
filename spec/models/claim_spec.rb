require 'rails_helper'

RSpec.describe(Claim) { describe('relationships') { it { is_expected.to(have_many(:claim_items).dependent(:destroy)) } } }
