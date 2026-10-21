RSpec.configure do |config|
  config.around(:each, :bullet) do |example|
    Bullet.enable = true
    Bullet.raise = true
    Bullet.unused_eager_loading_enable = false
    Bullet.start_request

    example.run

    Bullet.perform_out_of_channel_notifications if Bullet.notification?
  ensure
    Bullet.end_request
    Bullet.enable = false
  end
end
