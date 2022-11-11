import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "form" ]

    uncheckOtherPrimary(event) {
        var primaryCheckBoxes = document.getElementById('receivable-contacts-form').querySelectorAll('input[type="checkbox"]');

        if (primaryCheckBoxes.length == 1) {
            event.preventDefault();
            event.target.checked = true;
            // Prevent switching off primary if the contact is only 1
            return
        }

        if (event.target.checked != true) {
            return
        }

        primaryCheckBoxes.forEach(function(checkbox) {
            if (checkbox.id != event.target.id) {
                checkbox.checked = false
            }
        })

    }
}