module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale

    etag { I18n.locale }
  end

  private

  def accepted_language_tags = weighted_language_tags.sort_by.with_index { |(_tag, quality), index| [-quality, index] }.map(&:first)

  def available_locale_for(tag)
    I18n.available_locales.find { it.to_s.casecmp?(tag) } || I18n.available_locales.find { it.to_s.casecmp?(tag.split('-').first) }
  end

  def browser_locale = accepted_language_tags.lazy.filter_map { available_locale_for(it) }.first
  def preferred_locale = user_locale || session_locale || browser_locale || I18n.default_locale

  def remember_locale
    return if current_user != true_user

    if current_user.nil?
      session[:locale] = requested_locale if requested_locale
      return
    end

    locale = requested_locale || (session_locale || browser_locale unless user_locale)
    current_user.update(locale:) if locale && locale != user_locale
  end

  def requested_locale = (available_locale_for(params[:lang].to_s) if params[:lang].present?)
  def session_locale = (available_locale_for(session[:locale].to_s) if session[:locale].present?)

  def switch_locale(&)
    I18n.with_locale(preferred_locale, &)
    response.set_header('Vary', [response.get_header('Vary'), 'Accept-Language'].compact_blank.join(', '))
  end

  def user_locale = (available_locale_for(current_user.locale) if current_user&.locale.present?)

  def weighted_language_tags
    request.headers['Accept-Language'].to_s.split(',').filter_map do |entry|
      tag, *parameters = entry.split(';').map(&:strip)
      quality = parameters.find { it.start_with?('q=') }&.delete_prefix('q=')&.to_f || 1.0
      [tag, quality] if tag.present? && tag != '*' && quality.positive?
    end
  end
end
