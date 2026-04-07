# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'documentable' do
  let(:record) { create(described_class.to_s.snakecase.to_sym) }

  describe 'DOCUMENTABLE_TYPES' do
    it { expect(described_class::DOCUMENTABLE_TYPES).to(be_a(Array)) }

    described_class::DOCUMENTABLE_TYPES.each do |document_type|
      it { expect(record).to(respond_to(document_type)) }
    end
  end
end
