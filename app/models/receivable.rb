# frozen_string_literal: true

# == Schema Information
#
# Table name: receivables
#
# @!attribute id
#   @return []
# @!attribute authorized_at
#   @return [Time]
# @!attribute due_by
#   @return [Time]
# @!attribute invoiced
#   @return [Boolean]
# @!attribute paid_at
#   @return [Time]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute authorized_by_id
#   @return []
# @!attribute created_by_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute updated_by_id
#   @return []
#
# Indexes
#
#  index_receivables_on_authorized_at     (authorized_at)
#  index_receivables_on_authorized_by_id  (authorized_by_id)
#  index_receivables_on_created_by_id     (created_by_id)
#  index_receivables_on_due_by            (due_by)
#  index_receivables_on_invoiced          (invoiced)
#  index_receivables_on_paid_at           (paid_at)
#  index_receivables_on_shipment_id       (shipment_id)
#  index_receivables_on_updated_by_id     (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (authorized_by_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class Receivable < ApplicationRecord
  before_validation :set_total

  belongs_to :authorized_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  belongs_to :shipment
  has_one :broker_customer, through: :shipment

  has_many :receivable_items, autosave: true, dependent: :destroy

  monetize :total_cents, allow_nil: false

  scope :authorized, -> { where.not(authorized_at: nil) }
  scope :unauthorized, -> { where.not(id: authorized) }

  scope :paid, -> { where.not(paid_at: nil) }
  scope :unpaid, -> { where.not(id: paid) }

  validates :due_by, presence: true

  def self.build_from_shipment(shipment)
    new_receivable = new
    new_receivable.build_from_shipment(shipment)
    new_receivable
  end

  def build_from_shipment(shipment)
    assign_attributes(
      shipment: shipment,
      due_by: (shipment.picked_up_at + 30.days).end_of_day.in_time_zone('America/Los_Angeles')
    )

    self.receivable_items.map(&:mark_for_destruction) unless self.receivable_items.blank?

    self.receivable_items.build(
      charge: shipment.carrier_charge,
      description: shipment.items.map do |item|
        "#{item.quantity} #{item.packaging.name} #{item.desc} #{item.l && item.w && item.h ? "#{item.l}x#{item.w}x#{item.h}" : ''} #{item.forced_freight_class.blank? ? item.calculated_freight_class : item.forced_freight_class} #{ActionController::Base.helpers.number_with_delimiter item.weight} lbs"
      end.join("\n")
    )
  
    shipment.shipment_broker_accessorials.sort_by{ |shipment_broker_accessorial| shipment_broker_accessorial.broker_accessorial.name }.each do |shipment_broker_accessorial|
      next if shipment_broker_accessorial.broker_accessorial.broker_only?

      self.receivable_items.build(
        charge: shipment_broker_accessorial.charge,
        description: shipment_broker_accessorial.broker_accessorial.name.capitalize
      )
    end
    
    self
  end

  private

  def set_total
    return if self.receivable_items.blank?

    new_total = Money.new(0)
    self.receivable_items.each do |receivable_item|
      next if receivable_item.marked_for_destruction?
      new_total += receivable_item.charge
    end

    self.total = new_total
  end
end
