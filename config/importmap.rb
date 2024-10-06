# Pin npm packages by running ./bin/importmap

pin "application"
pin "sortable", to: "sortable.js"
pin "turbo_progress_bar", to: "turbo_progress_bar.js"

pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"

# See https://github.com/rails/importmap-rails/issues/65#issuecomment-1838005148
pin "bootstrap" # @5.3.3
pin "@popperjs/core", to: "@popperjs--core--esm.js" # @2.11.8

pin "stimulus-flatpickr" # @3.0.0
pin "flatpickr" # @4.6.13
