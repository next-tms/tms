class BrokerPolicy < ActionPolicy::Base
  def show?
    user.broker == record.broker
  end
end
