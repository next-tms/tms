module SeedSettings
  def seed_settings
    YAML.safe_load_file(Rails.root.join('db/seed/settings.yaml')).fetch('settings').each do |setting|
      create(:setting, **setting.symbolize_keys) unless Setting.exists?(key: setting.fetch('key'))
    end
  end
end

RSpec.configure { |config| config.include(SeedSettings, type: :request) }
