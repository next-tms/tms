require("@rails/activestorage").start()

import * as Turbo from "@hotwired/turbo"
// Turbo.session.drive = true

import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'

const application = Application.start()
const context = require.context('./controllers', true, /\.js$/)
application.load(definitionsFromContext(context))

import Flatpickr from 'stimulus-flatpickr'
application.register('flatpickr', Flatpickr)

import { Tooltip, Toast, Popover } from 'bootstrap'
import 'src/application.scss'

import './sortable'

const images = require.context('../images', true)
