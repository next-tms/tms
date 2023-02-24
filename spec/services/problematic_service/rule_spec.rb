# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(ProblematicService::Rule) do
  describe 'class methods' do
    subject { described_class }

    it { is_expected.to(respond_to(:all)) }
    it { is_expected.to(respond_to(:code)) }
    it { is_expected.to(respond_to(:model)) }
  end
end
