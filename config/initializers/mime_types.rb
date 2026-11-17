# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register 'application/pdf', :pdf
Mime::Type.register 'application/vnd.nmfta.ebol+json', :ebol

ActiveSupport.on_load(:action_view) { ActionView::Template::Handlers::ERB.escape_ignore_list |= [Mime[:md].to_s] }
