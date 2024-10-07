class ContactPolicy < ApplicationPolicy
  BROKER_ATTRIBUTES = %i[ comments email first_name job_title label last_name mobile_phone work_phone ]
  CUSTOMER_ATTRIBUTES = []

  include AuthorizedAttributablePolicy
end
