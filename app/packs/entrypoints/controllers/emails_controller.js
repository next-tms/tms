import { Controller } from "stimulus"

export default class extends Controller {
    connect(e) {
        document.body.querySelectorAll('input[type="email"]').forEach((input) => {
            input.addEventListener('blur', () => {
                input.value = input.value.toLowerCase()
            })
        })
    }
}
