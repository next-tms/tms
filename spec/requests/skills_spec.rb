require 'rails_helper'

RSpec.describe('Skills') do
  describe 'GET /skills/tms/SKILL.md' do
    let(:filter_keys) { response.body.scan(/\{"([a-z0-9_]+)":/).flatten }
    let(:frontmatter) { YAML.safe_load(response.body[/\A---\n(.*?)\n---\n/m, 1]) }

    before do
      seed_settings
      get('/skills/tms/SKILL.md')
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.media_type).to(eq('text/markdown')) }
    it { expect(response.headers['Cache-Control']).to(include('public')) }
    it { expect(frontmatter).to(include('description' => include('www.example.com'), 'name' => 'tms')) }
    it { expect(response.body).to(include('http://www.example.com/mcp', 'http://www.example.com/account/api-keys/new')) }
    it { expect(response.body).to(include(*MCPController::TOOLS.map { |tool| "`#{tool.name_value}`" })) }
    it { expect(response.body).to(include("--scope user #{MCPController.server_name} ", "[mcp_servers.#{MCPController.server_name}]")) }
    it { expect(response.body).to(include("Bearer $#{MCPController.server_name.underscore.upcase}_API_KEY")) }
    it { expect(filter_keys).to(be_present) }
    it { expect(filter_keys.map { |key| key.camelize(:lower) }).to(all(be_in(Types::ShipmentFilterType.arguments.keys))) }

    context 'with a name that YAML and HTML would escape' do
      let(:name) { 'A & B: Freight' }

      before do
        Setting.find_by!(key: 'name').update!(value: name)
        get('/skills/tms/SKILL.md')
      end

      it { expect(frontmatter['description']).to(include(name)) }
      it { expect(response.body).to(include("# #{name} TMS")) }
    end
  end
end
