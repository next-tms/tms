import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "form" ]

    uncheckOtherPrimary(event) {
        if (event.target.checked != true) {
            return
        }

        document.getElementById('contacts-form').querySelectorAll('input[type="checkbox"]').forEach(function(checkbox) {
            if (checkbox.id != event.target.id) {
                checkbox.checked = false
            }
        })

    }
}
