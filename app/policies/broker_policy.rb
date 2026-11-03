class BrokerPolicy < ApplicationPolicy
  relation_scope { |relation| broker? ? relation : relation.none }

  def show? = broker?
end
