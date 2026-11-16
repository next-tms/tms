require 'rails_helper'

RSpec.shared_examples_for('filterable GraphQL resolver') do
  let(:graphql_name) { described_class.name.demodulize.delete_suffix('sResolver') }

  it { expect(described_class.arguments.keys).to(contain_exactly('filter', 'page', 'pageSize', 'sort')) }
  it { expect(described_class.arguments['filter'].type.graphql_name).to(eq("#{graphql_name}Filter")) }
  it { expect(described_class.arguments['sort'].type.to_type_signature).to(eq('[String!]')) }
  it { expect(described_class.type.to_type_signature).to(eq("#{graphql_name}Collection!")) }
end
