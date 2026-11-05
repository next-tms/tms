require 'rails_helper'

RSpec.describe(LiftoffSchema) do
  describe '.did_you_mean' do
    subject { described_class.did_you_mean }

    it { is_expected.to(be_nil) }
  end

  describe '.visibility' do
    subject { described_class.visibility }

    it { is_expected.to(be_a(GraphQL::Schema::Visibility)) }
  end
end
