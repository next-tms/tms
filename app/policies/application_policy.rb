class ApplicationPolicy
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization
  include ActionPolicy::Policy::PreCheck
  include ActionPolicy::Policy::Reasons
  include ActionPolicy::Policy::Aliases
  include ActionPolicy::Policy::Scoping
  include ActionPolicy::Policy::Cache
  include ActionPolicy::Policy::CachedApply

  extend ActionPolicy::ScopeMatchers::ActionControllerParams
  extend ActionPolicy::ScopeMatchers::ActiveRecord

  prepend ActionPolicy::Policy::Rails::Instrumentation

  alias_rule :new?, to: :create?

  authorize :authorizable

  default_rule :manage?

  scope_matcher :action_controller_params, ActionController::Parameters
  scope_matcher :active_record_relation, ActiveRecord::Relation

  def create? = false
  def index? = false
  def manage? = false

  private

  def broker? = authorizable.broker?
  def carrier? = authorizable.carrier?
  def companyable = authorizable.companyable
  def customer? = authorizable.customer?
end
