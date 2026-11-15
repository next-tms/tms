module Geo
  class << self
    def place(place_id, provider:)
      best(providers(:place).select { it.resolves?(provider) }) { it.place(place_id, provider:)&.then { |place| place if known?(place) } }
    end

    def time_zone(**location) = best(providers(:time_zone, **location)) { it.time_zone(**location) }&.id

    def verify(**postal_address)
      verifications = providers(:geocode, :verification, **postal_address).each_with_object([]) do |provider, verifications|
        break verifications if complete?(verifications, provider)

        verification = provider.verify(**postal_address)
        verifications << verification if verification
      end

      merge(ranked(verifications))
    end

    private

    def authoritative?(answer, provider) = rank(answer.authority) <= rank(provider.authority)

    def best(providers)
      answers = providers.each_with_object([]) do |provider, answers|
        break answers if answers.any? { authoritative?(it, provider) }

        answer = yield(provider)
        answers << answer if answer
      end

      ranked(answers).first
    end

    def complete?(verifications, provider) = verifications.any? { authoritative?(it, provider) } && located?(verifications)
    def known?(place) = place.types.any? || !place.permanently_closed.nil?
    def located?(verifications) = verifications.any?(&:latitude) && verifications.any? { it.place_id || it.places }

    def merge(verifications)
      verification = verifications.first
      return if verification.nil?

      geocode = ranked(verifications.select(&:latitude), :geocode_authority).first
      located = verifications.find(&:place_id)

      verification.with(
        dock: verifications.find { !it.dock.nil? }&.dock,
        fingerprint: verifications.find(&:fingerprint)&.fingerprint,
        geocode_authority: geocode&.geocode_authority,
        latitude: geocode&.latitude,
        longitude: geocode&.longitude,
        place_id: located&.place_id,
        place_provider: located&.place_provider,
        places: verifications.find { !it.places.nil? }&.places
      )
    end

    def providers(*roles, **query) = Providers.enabled.select { it.roles.intersect?(roles) && it.supports?(**query) }
    def rank(authority) = Providers::AUTHORITIES.index(authority) || Providers::AUTHORITIES.size
    def ranked(answers, by = :authority) = answers.sort_by.with_index { |answer, index| [rank(answer.public_send(by)), index] }
  end
end
