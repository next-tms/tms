require("@rails/activestorage").start()

import mrujs from "mrujs"
import * as Turbo from "@hotwired/turbo"

window.Turbo = Turbo
mrujs.start()

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

import Flatpickr from "stimulus-flatpickr"
application.register("flatpickr", Flatpickr)
require("flatpickr/dist/flatpickr.css")

import { Tooltip, Toast, Popover } from "bootstrap"
import "src/application.scss"

import "./sortable"

const images = require.context("../images", true)
