# frozen_string_literal: true

require 'test_helper'

class Mutations::AuthenticateTest < ActiveSupport::TestCase
  def perform(args = {})
    Mutations::Authenticate.new(object: nil, field: nil, context: { session: {} }).resolve(**args)
  end

  def create_user
    broker = Broker.create!(
      address: Address.new(
        city: Faker::Address.city,
        street: Faker::Address.street_address,
        region: Region.new(
          abbreviation: Faker::Address.state_abbr,
          country: Country.new(alpha3_code: 'USA'),
          name: 'United States of America'
        )
      ),
      customer_service_email: 'cs@example.com',
      name: Faker::Company.name,
      phone: Faker::PhoneNumber.cell_phone_in_e164,
      time_zone_name: Faker::Address.time_zone,
      websites: [
        Website.new(
          domain: Faker::Internet.domain_name,
          footer_url: 'https://localhost/footer.html',
          manifest_url: 'https://localhost/manifest.json',
          sign_out_url: 'https://example.com'
        )
      ]
    )

    user = User.create!(
      broker:,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.email,
      password: Faker::Internet.password,
      skip_invitation: true
    )

    user.update_columns(invitation_token: nil, invitation_accepted_at: DateTime.current)

    user
  end

  test 'success' do
    user = create_user

    result = perform(
      credentials: {
        email: user.email,
        password: user.password
      }
    )

    assert result[:token].present?
    assert_equal result[:user], user
  end

  test 'failure because no credentials' do
    assert_nil perform
  end

  test 'failure because wrong email' do
    create_user
    assert_nil perform(credentials: { email: 'wrong' })
  end

  test 'failure because wrong password' do
    user = create_user
    assert_nil perform(credentials: { email: user.email, password: 'wrong' })
  end
end
