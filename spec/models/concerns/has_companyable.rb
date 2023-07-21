# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'has_companyable' do
  let(:record) { create(described_class.to_s.snakecase.to_sym) }

  describe 'relationships' do
    subject { build(described_class.to_s.snakecase.to_sym) }

    it { is_expected.to(belong_to(:companyable)) }
  end
end
