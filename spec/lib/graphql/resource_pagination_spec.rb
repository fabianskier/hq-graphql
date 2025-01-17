require 'rails_helper'

describe ::HQ::GraphQL::Resource do
  let!(:manager_resource) do
    Class.new do
      include ::HQ::GraphQL::Resource
      self.model_name = "Manager"

      root_query
    end
  end

  let!(:user_resource) do
    Class.new do
      include ::HQ::GraphQL::Resource
      self.model_name = "User"

      sort_fields :name

      root_query
    end
  end

  let(:root_query) do
    Class.new(::HQ::GraphQL::RootQuery)
  end

  let(:schema) do
    Class.new(::GraphQL::Schema) do
      query(RootQuery)
      use(::GraphQL::Batch)
    end
  end

  let(:association_fields) { ["offset", "limit", "sortBy", "sortOrder"] }
  let(:connection_fields) { ["before", "after", "first", "last"] }
  let(:query_fields) { association_fields + connection_fields + ["filters"] }
  let(:root_fields) { root_query.fields }
  let(:managers_field) { root_fields["managers"] }
  let(:managers_arguments) { managers_field.arguments }
  let(:users_field) { root_fields["users"] }
  let(:users_arguments) { users_field.arguments }

  before(:each) do
    allow(::HQ::GraphQL.config).to receive(:use_experimental_associations) { true }
    stub_const("RootQuery", root_query)
    schema.load_types!
  end

  it "adds pagination to the root query and pagination queries" do
    expect(root_fields.keys).to contain_exactly("manager", "managers", "user", "users")
    expect(managers_arguments.keys).to contain_exactly(*query_fields)
    expect(users_arguments.keys).to contain_exactly(*query_fields)
  end

  it "adds enums to sort fields" do
    expect(managers_arguments["sortOrder"].type).to eq HQ::GraphQL::Enum::SortOrder
    expect(managers_arguments["sortBy"].type).to eq HQ::GraphQL::Enum::SortBy
    expect(HQ::GraphQL::Enum::SortBy.values.keys).to contain_exactly("CreatedAt", "UpdatedAt")

    expect(users_arguments["sortOrder"].type).to eq HQ::GraphQL::Enum::SortOrder
    expect(users_arguments["sortBy"].type).not_to eq HQ::GraphQL::Enum::SortBy
    expect(users_arguments["sortBy"].type).to eq user_resource.sort_fields_enum
    expect(user_resource.sort_fields_enum.values.keys).to contain_exactly("CreatedAt", "UpdatedAt", "Name")
  end

  it "adds pagination to association fields" do
    users_field = manager_resource.query_object.fields["users"]
    users_arguments = users_field.arguments
    expect(users_field.arguments.keys).to contain_exactly(*association_fields)
    expect(users_arguments["sortOrder"].type).to eq HQ::GraphQL::Enum::SortOrder
    expect(users_arguments["sortBy"].type).not_to eq HQ::GraphQL::Enum::SortBy
    expect(users_arguments["sortBy"].type).to eq user_resource.sort_fields_enum
    expect(user_resource.sort_fields_enum.values.keys).to contain_exactly("CreatedAt", "UpdatedAt", "Name")
  end
end
