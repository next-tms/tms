### Configure Geocoder config for smarty_streets to ensure Auth Keys are stored (For MainStreet Gem)

if ENV['SMARTY_STREETS_AUTH_ID']
  Geocoder.config[:smarty_streets] ||= { api_key: [ENV['SMARTY_STREETS_AUTH_ID'], ENV.fetch('SMARTY_STREETS_AUTH_TOKEN', nil)] }
end
