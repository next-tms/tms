import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ 'length', 'width', 'height', 'nmfc', 'weight' ]

    fromLength(e) {
        var dimensions = null

        if (this.lengthTarget.value.toLowerCase().indexOf('x') > -1) {
            dimensions = this.lengthTarget.value.toLowerCase().split('x')
        }

        if (this.lengthTarget.value.toLowerCase().indexOf('*') > -1) {
            dimensions = this.lengthTarget.value.toLowerCase().split('*')
        }

        if (dimensions.length < 2) {
            return
        }

        if (dimensions[2].indexOf(' ') >= 0 && dimensions[2].toLowerCase().indexOf('lbs') >= 0) {
            this.lengthTarget.value = dimensions[0].trim()
            this.widthTarget.value = dimensions[1].trim()

            const height = dimensions[2].split(' ')[0].trim()
            const weight = dimensions[2].split(' ')[1].trim()

            this.heightTarget.value = height
            this.weightTarget.value = weight

            this.nmfcTarget.focus()
        } else {
            this.lengthTarget.value = dimensions[0].trim()
            this.widthTarget.value = dimensions[1].trim()
            this.heightTarget.value = dimensions[2].trim()
            this.weightTarget.focus()
        }

        this.cleanup()
    }

    // private

    cleanup() {
        this.lengthTarget.value = this.lengthTarget.value.replace(/\D/g,'')
        this.widthTarget.value = this.widthTarget.value.replace(/\D/g,'')
        this.heightTarget.value = this.heightTarget.value.replace(/\D/g,'')
        this.weightTarget.value = this.weightTarget.value.replace(/\D/g,'')
    }
}
