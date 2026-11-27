class AccessorialPolicy < ApplicationPolicy
  relation_scope do |relation|
    next relation if broker?
    next relation.eligible(broker_customer: companyable).offered if customer?

    relation.none
  end
end
