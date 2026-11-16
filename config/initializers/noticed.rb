ActiveSupport.on_load(:noticed_notification) do
  class << self
    def policy_name = 'NotificationPolicy'
  end
end
