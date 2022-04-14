import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { controller: String, action: String }

    connect(e) {
        const controller_classes = 'a.' + this.controllerValue
        const controller_action_classes = 'a.' + this.controllerValue + '-' + this.actionValue

        document.body.querySelectorAll(controller_classes).forEach((a) => {
            a.classList.add('active')
            a.classList.add('fw-bold')
        })

        document.body.querySelectorAll(controller_action_classes).forEach((a) => {
            a.classList.add('active')
            a.classList.add('fw-bold')
        })
    }
}
