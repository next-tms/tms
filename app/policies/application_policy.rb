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

  alias_rule :create?, :destroy?, :edit?, :new?, :update?, to: :manage?
  alias_rule :show?, to: :view?

  def admin?
    return false unless any_role?(:root)

    return true if broker?

    record.try(authorizable.companyable.model_name.singular.to_sym) == authorizable.companyable
  end

  def any_role?(*roles) = authorizable.any_role?(*roles)
  def broker? = authorizable.broker?
  def carrier? = authorizable.carrier?
  def customer? = authorizable.customer?
  def manage? = admin? || owner? || party?

  def owner?
    companyable_owner? ||
      record.try(:created_by) == authorizable ||
      record.try(:user) == authorizable
  end

  def party?
    owner? || authorizable.roles.any? do |role|
      record.try(role) == authorizable || record.try(role.to_s.pluralize.to_sym)&.include?(authorizable)
    end
  end

  def view? = party?

  private

  def companyable_owner?
    return false if broker?

    record == authorizable.companyable || record.try(authorizable.companyable.model_name.singular.to_sym) == authorizable.companyable
  end
end
