class DSDC::CarrierController < DSDC::ApplicationController
  before_action :set_payment_transactions

  rescue_from ActionController::ParameterMissing, ArgumentError, Money::Currency::UnknownCurrency, with: :render_formatting_error
  rescue_from ActiveRecord::SoleRecordExceeded, with: :render_not_found
  rescue_from Money::Bank::UnknownRate, with: :render_business_error

  wrap_parameters false

  private

  def render_business_error = render_errors('500')
  def render_errors(*codes, status: :bad_request) = render('dsdc/carrier/errors', locals: { codes: }, status:)
  def render_formatting_error = render_errors('400')
  def render_not_found = render_errors('300', status: :not_found)

  def set_payment_transactions
    query = request.query_parameters
    filters = query.slice('DOT', 'MC', 'shipmentID', 'uniqueID')
    filters['invoiceHeader'] = { 'invoiceNumber' => query['invoiceNumber'] } if query['invoiceNumber'].present?

    @payment_transactions = authorized_scope(PaymentTransaction.all).where('dsdc_invoice @> ?', filters.to_json).order(:created_at)
  end
end
