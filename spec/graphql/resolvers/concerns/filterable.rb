require 'rails_helper'

RSpec.shared_examples_for('filterable GraphQL resolver') do
  it { expect(described_class.arguments.keys).to(contain_exactly('filter', 'page', 'pageSize', 'sort')) }
  it { expect(described_class.arguments['filter'].type.graphql_name).to(eq("#{described_class::MODEL.name}Filter")) }
  it { expect(described_class.arguments['sort'].type.to_type_signature).to(eq('[String!]')) }
  it { expect(described_class.type.to_type_signature).to(eq("#{described_class::MODEL.name}Collection!")) }
end
