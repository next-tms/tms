module BrokerHelper
  def humanized_notification_type(notification_type)
    entity, action = notification_type.split(':')

    "#{entity.capitalize} - #{action.gsub('_id', '').humanize}"
  end
end
