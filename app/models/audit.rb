class Audit < Audited::Audit
  class << self
    def ransackable_associations(_auth_object = nil) = []
    def ransackable_attributes(_auth_object = nil) = ['action', 'auditable_id', 'created_at']
  end
end
