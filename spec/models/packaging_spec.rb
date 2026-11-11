# == Schema Information
#
# Table name: packagings
#
# @!attribute id
#   @return []
# @!attribute freight_kit_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_freight_kit_type  (freight_kit_type)
#  index_packagings_on_name              (name) UNIQUE
#
# @!attribute id
#   @return []
# @!attribute freight_kit_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_freight_kit_type  (freight_kit_type)
#  index_packagings_on_name              (name) UNIQUE
#
require 'rails_helper'

RSpec.describe(Packaging) { describe('relationships') { it { is_expected.to(have_many(:items).dependent(:restrict_with_error)) } } }
