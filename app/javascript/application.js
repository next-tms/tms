require("@rails/activestorage").start()

import mrujs from "mrujs"
import * as Turbo from "@hotwired/turbo-rails"

window.Turbo = Turbo
mrujs.start()

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
const context = require.context("./src/controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

import Flatpickr from "stimulus-flatpickr"
application.register("flatpickr", Flatpickr)
require("flatpickr/dist/flatpickr.css")

import { Tooltip, Toast, Popover } from "bootstrap"
import "application.scss"

import "./src/sortable"
import "./page_navigation_loader"

const images = require.context("./images", true)
