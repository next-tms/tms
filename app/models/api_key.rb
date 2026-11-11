# == Schema Information
#
# Table name: api_keys
#
# @!attribute id
#   @return []
# @!attribute expires_at
#   @return [Time]
# @!attribute last_used_at
#   @return [Time]
# @!attribute name
#   @return [String]
# @!attribute token
#   @return [String]
# @!attribute token_digest
#   @return [String]
# @!attribute token_suffix
#   @return [String]
# @!attribute ttl
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute rolled_from_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_api_keys_on_rolled_from_id  (rolled_from_id)
#  index_api_keys_on_token_digest    (token_digest) UNIQUE
#  index_api_keys_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (rolled_from_id => api_keys.id)
#  fk_rails_...  (user_id => users.id)
#
# @!attribute id
#   @return []
# @!attribute expires_at
#   @return [Time]
# @!attribute last_used_at
#   @return [Time]
# @!attribute name
#   @return [String]
# @!attribute token
#   @return [String]
# @!attribute token_digest
#   @return [String]
# @!attribute token_suffix
#   @return [String]
# @!attribute ttl
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute rolled_from_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_api_keys_on_rolled_from_id  (rolled_from_id)
#  index_api_keys_on_token_digest    (token_digest) UNIQUE
#  index_api_keys_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (rolled_from_id => api_keys.id)
#  fk_rails_...  (user_id => users.id)
#
class APIKey < ApplicationRecord
  class << self
    def authenticate(token) = token.presence && find_by(token_digest: digest(token))
    def digest(token) = OpenSSL::Digest::SHA256.hexdigest(token.to_s)
    def ransackable_associations(_auth_object = nil) = []
    def ransackable_attributes(_auth_object = nil) = ['created_at', 'expires_at', 'last_used_at', 'name', 'token_suffix']
  end

  EXPIRES_SOON = 7.days
  MAX_TTL = 180.days
  ROLL_GRACE_PERIOD = 8.hours
  TOKEN_PREFIX = 'tms_'.freeze
  TTLS = [1.day, 7.days, 30.days, 60.days, 90.days, 180.days].freeze

  audited except: %i[last_used_at token token_digest]

  before_validation :set_token, on: :create
  before_validation :set_expires_at, on: :create

  belongs_to :rolled_from, class_name: 'APIKey', inverse_of: :rolled_to, optional: true
  belongs_to :user

  encrypts :token

  has_one :rolled_to, class_name: 'APIKey', dependent: :nullify, foreign_key: :rolled_from_id, inverse_of: :rolled_from

  scope :active, -> { where(expires_at: nil).or(where(expires_at: Time.current..)) }
  scope :expired, -> { where(expires_at: ...Time.current) }

  validates :expires_at, comparison: { less_than_or_equal_to: -> { MAX_TTL.from_now } }, if: :expires_at, on: :create
  validates :expires_at, :ttl, presence: true
  validates :name, :token, :token_digest, :token_suffix, presence: true
  validates :name, length: { maximum: 100 }
  validates :ttl, allow_nil: true, comparison: { greater_than: 0.seconds, less_than_or_equal_to: MAX_TTL }

  def active? = !expired?
  def expired? = expires_at.present? && expires_at.past?
  def expires_soon? = active? && expires_at.present? && expires_at.before?(EXPIRES_SOON.from_now)

  def roll!(grace_period: ROLL_GRACE_PERIOD)
    with_lock do
      next rolled_to if rolled_to

      update!(expires_at: [expires_at, grace_period.from_now].compact.min)
      user.api_keys.create!(name:, rolled_from: self, ttl:)
    end
  end

  def use! = last_used_at&.after?(1.minute.ago) || update!(last_used_at: Time.current)

  private

  def set_token
    self.token = "#{TOKEN_PREFIX}#{SecureRandom.base58(43)}"
    self.token_digest = self.class.digest(token)
    self.token_suffix = token.last(4)
  end

  def set_expires_at = self.expires_at ||= ttl && (Time.current + ttl)
end
