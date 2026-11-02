import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "pickupOn", "reason" ]
    static values = { acceptedOn: String }

    toggle() {
        const rescheduled = this.acceptedOnValue !== '' && this.pickupOnTarget.value.slice(0, 10) !== this.acceptedOnValue
        const reason = this.reasonTarget.querySelector('select').value !== ''

        this.reasonTarget.hidden = !(rescheduled || reason)
    }
}
