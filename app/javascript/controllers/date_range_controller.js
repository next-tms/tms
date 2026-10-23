import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["range", "select"]

    connect() {
        this.update()
    }

    update() {
        this.rangeTarget.classList.toggle("d-none", this.selectTarget.value === "")
    }
}
