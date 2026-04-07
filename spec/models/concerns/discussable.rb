# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

shared_examples_for 'discussable' do
  let(:record) { build(described_class.name.underscore.to_sym) }

  describe 'relationships' do
    it { expect(record).to(have_many(:discussion_topics)) }
    it { expect(record).to(have_many(:comments).through(:discussion_topics)) }
    it { expect(record).to(have_one(:discussion).dependent(:destroy)) }
  end

  describe 'included methods' do
    it { expect(record).to(respond_to(:discussable?)) }
    it { expect(record).to(respond_to(:eligible_discussable_contacts)) }
  end

  describe 'when initialized' do
    it 'builds an associated Discussion' do
      expect(record.discussion).not_to(be_nil)
    end
  end
end
