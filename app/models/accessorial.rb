class Accessorial < ApplicationRecord
  class << self
    def catalog
      accessorials = all.to_a
      transponder_codes = accessorials.filter_map(&:transponder_code)
      missing = Transponder::ORM::Accessorial.all.reject { |transponder_accessorial| transponder_codes.include?(transponder_accessorial.code) }

      [*accessorials, *missing.map { |transponder_accessorial| from_transponder(transponder_accessorial) }].sort_by(&:name)
    end

    def eligible(broker_customer: nil)
      return blanket.order(:name) if broker_customer.nil?

      overrides = broker_customer.accessorials.to_a
      overridden = blanket.select { |accessorial| overrides.any? { |override| override.overrides?(accessorial) } }

      where(broker_customer:).or(blanket.where.not(id: overridden)).order(:name)
    end

    def with_transponder_codes(transponder_codes, broker_customer: nil)
      transponder_codes = Array(transponder_codes).map(&:to_s).uniq
      existing = eligible(broker_customer:).where(transponder_code: transponder_codes).reorder(:broker_only, :id).uniq(&:transponder_code)
      accessorials = existing.index_by(&:transponder_code)

      transponder_codes.filter_map do |transponder_code|
        next accessorials[transponder_code] if accessorials.key?(transponder_code)

        transponder_accessorial = Transponder::ORM::Accessorial.find_by(code: transponder_code)
        from_transponder(transponder_accessorial) if transponder_accessorial
      end
    end

    private

    def from_transponder(transponder_accessorial)
      new(broker_only: false, name: transponder_accessorial.name, transponder_code: transponder_accessorial.code)
    end
  end

  belongs_to :broker_customer, optional: true

  belongs_to_orm :transponder_accessorial, class_name: 'Transponder::ORM::Accessorial', foreign_key: :transponder_code, optional: true

  monetize :flat_charge_cents, allow_nil: true
  monetize :upcharge_cents, allow_nil: true

  scope :blanket, -> { where(broker_customer: nil) }
  scope :offered, -> { where.not(transponder_code: nil).or(where(broker_only: false)) }

  validates :code, presence: true, unless: :transponder_code?
  validates :name, presence: true

  def cache_version = super || transponder_code
  def key = persisted? ? id.to_s : transponder_code
  def offered? = transponder_code? || !broker_only?

  def overrides?(accessorial)
    (code.present? && code == accessorial.code) || (transponder_code.present? && transponder_code == accessorial.transponder_code)
  end
end
