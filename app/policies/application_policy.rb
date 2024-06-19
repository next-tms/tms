# frozen_string_literal: true

# See https://github.com/palkan/action_policy/blob/master/docs/custom_policy.md#
class ApplicationPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization
  include ActionPolicy::Policy::PreCheck
  include ActionPolicy::Policy::Reasons
  include ActionPolicy::Policy::Aliases
  include ActionPolicy::Policy::Scoping
  include ActionPolicy::Policy::Cache
  include ActionPolicy::Policy::CachedApply

  # Rails-specific scoping extensions
  extend ActionPolicy::ScopeMatchers::ActiveRecord
  scope_matcher :active_record_relation, ActiveRecord::Relation
  extend ActionPolicy::ScopeMatchers::ActionControllerParams
  scope_matcher :action_controller_params, ActionController::Parameters

  # Active Support notifications
  prepend ActionPolicy::Policy::Rails::Instrumentation

  authorize :authorizable

  default_rule :manage?

  alias_rule :create?, :destroy?, :edit?, :new?, :update?, :view?, to: :manage?
  alias_rule :show?, to: :view?

  def admin?
    any_role?(:root)
  end

  def any_role?(*roles)
    authorizable.any_role?(*roles)
  end

  def broker?
    authorizable.companyable.broker?
  end

  def carrier?
    authorizable.companyable.carrier?
  end

  def customer?
    authorizable.companyable.customer?
  end

  def manage?
    owner? || (broker? && admin?)
  end

  def owner?
    record.try(:user) == authorizable
  end
end
