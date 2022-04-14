import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    copy(e) {
        e.currentTarget.select()
        document.execCommand("copy")
    }
}
