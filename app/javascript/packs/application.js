require.context('../images', true)

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
// require("channels")

import 'src/application.scss'

// Bootstrap
import 'bootstrap/dist/js/bootstrap'

// Global
import flatpickr from 'flatpickr'
import 'jquery-timepicker/jquery.timepicker'
import 'jquery-timepicker/jquery.timepicker.css'

import './global'
import './custom'
