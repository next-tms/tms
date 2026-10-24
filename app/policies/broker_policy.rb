class BrokerPolicy < ActionPolicy::Base
  def show? = user.broker?
end
