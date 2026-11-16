class BrokerWare::DocumentDeliveriesController < BrokerWare::ApplicationController
  MAILER_ACTIONS = BrokerWare::DOCUMENT_NAMES.invert.freeze
  MAX_EMAILS = 10
  PERMITTED = [:load_id, { document_names: [], emails: [] }].freeze

  wrap_parameters :document_delivery, format: :json, include: ['documentNames', 'emails', 'loadId']

  def create
    delivery = params.expect(document_delivery: PERMITTED).to_h.deep_symbolize_keys
    shipment = authorized_scope(Shipment.all).find_by!(load_id: require_param(delivery, :load_id))
    authorize!(shipment, to: :view?)

    emails = Array(delivery[:emails]).compact_blank.uniq
    mailer_actions = Array(delivery[:document_names]).map { |document_name| MAILER_ACTIONS[document_name] }

    if emails.empty? || emails.size > MAX_EMAILS || emails.any? { |email| !email.match?(URI::MailTo::EMAIL_REGEXP) }
      render_error(t('.invalid_emails', max: MAX_EMAILS), status: :bad_request)
      return
    end

    if mailer_actions.empty? || mailer_actions.any?(&:nil?)
      render_error(t('.unknown_documents', names: BrokerWare::DOCUMENT_NAMES.values.to_sentence), status: :bad_request)
      return
    end

    emails.product(mailer_actions).each do |email, mailer_action|
      ContactMailer.public_send(mailer_action, from_user: current_user, shipment:, to_contact: Contact.new(email:)).deliver_now
    end

    head(:ok)
  end
end
