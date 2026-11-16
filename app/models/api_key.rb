class APIKey < ApplicationRecord
  class << self
    def authenticate(token, **attributes) = token.presence && find_by(**attributes, token_digest: digest(token))
    def digest(token) = OpenSSL::Digest::SHA256.hexdigest(token.to_s)
    def ransackable_associations(_auth_object = nil) = []
    def ransackable_attributes(_auth_object = nil) = ['created_at', 'expires_at', 'last_used_at', 'name', 'token_suffix']
  end

  ACCESS_TOKEN_TTL = 1.day
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
  validates :client_id, :name, :token, :token_digest, :token_suffix, presence: true
  validates :name, length: { maximum: 100 }
  validates :ttl, allow_nil: true, comparison: { greater_than: 0.seconds, less_than_or_equal_to: MAX_TTL }

  def access_token = signed_id(expires_in: access_token_ttl, purpose: :access_token)
  def access_token_ttl = [ACCESS_TOKEN_TTL, expires_at && (expires_at - Time.current).seconds].compact.min
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
    self.client_id = SecureRandom.hex(16)
    self.token = "#{TOKEN_PREFIX}#{SecureRandom.base58(43)}"
    self.token_digest = self.class.digest(token)
    self.token_suffix = token.last(4)
  end

  def set_expires_at = self.expires_at ||= ttl && (Time.current + ttl)
end
