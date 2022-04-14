import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ 'input' ]

    handle(e) {
        var num = e.currentTarget.value
        num = num.replace(/[^\d.-]/g, '')
        num = parseFloat(num)
        num = num.toFixed(2)

        if (isNaN(num)) {
            e.currentTarget.value = '0.00'
        } else {
            e.currentTarget.value = num
        }
    }
}
