require 'rails_helper'

RSpec.describe('llms.txt') do
  describe 'GET /llms.txt' do
    before do
      seed_settings
      get('/llms.txt')
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.media_type).to(eq('text/plain')) }
    it { expect(response.headers['Cache-Control']).to(include('public')) }
    it { expect(response.body).to(start_with("# #{Setting.value!(:name)} TMS\n\n> ")) }
    it { expect(response.body).to(include('http://www.example.com/mcp', 'http://www.example.com/skills/tms/SKILL.md')) }
  end
end
