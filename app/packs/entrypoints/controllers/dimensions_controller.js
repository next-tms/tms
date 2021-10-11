import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ 'length', 'width', 'height', 'weight', 'forcedClass' ]

    fromLength(e) {
        var dimensions = null
        var seperator = null

        if (this.lengthTarget.value.toLowerCase().indexOf('x') > -1) {
            seperator = 'x'
        } else if (this.lengthTarget.value.toLowerCase().indexOf('x') > -1) {
            seperator = 'x'
        } else if (this.lengthTarget.value.toLowerCase().indexOf('*') > -1) {
            seperator = '*'
        }

        if (seperator) {
            dimensions = this.lengthTarget.value.toLowerCase().split(seperator)
        } else {
            return
        }

        if (dimensions.length < 2) {
            return
        }

        if (dimensions[2].indexOf(' ') >= 0 && dimensions[2].toLowerCase().indexOf('lbs') >= 0) {
            this.lengthTarget.value = dimensions[0]
            this.widthTarget.value = dimensions[1]
            this.heightTarget.value = dimensions[2].split(' ')[0]
            this.weightTarget.value = dimensions[2].split(' ')[1]
        } else if (dimensions[0].indexOf(' ') >= 0 && dimensions[0].toLowerCase().indexOf('lbs') >= 0) {
            this.lengthTarget.value = dimensions[0].split(' ')[1]
            this.widthTarget.value = dimensions[1]
            this.heightTarget.value = dimensions[2]
            this.weightTarget.value = dimensions[0].split(' ')[0]
        } else {
            this.lengthTarget.value = dimensions[0]
            this.widthTarget.value = dimensions[1]

            if (dimensions[2].indexOf(' ') >= 0) {
                this.heightTarget.value = dimensions[2].split(' ')[0]
                this.weightTarget.value = dimensions[2].split(' ')[1]
            } else {
                this.heightTarget.value = dimensions[2]
            }
        }

        this.cleanup()
    }

    // private

    cleanup() {
        var l = null
        var w = null
        var h = null
        var weight = null

        if (this.lengthTarget.value.toLowerCase().indexOf('w') !== -1) {
          w = this.lengthTarget.value
        } else if (this.lengthTarget.value.toLowerCase().indexOf('h') !== -1) {
          h = this.lengthTarget.value
        } else if (this.lengthTarget.value.toLowerCase().indexOf('lbs') !== -1) {
          weight = this.lengthTarget.value
        }

        if (this.widthTarget.value.toLowerCase().indexOf('l') !== -1) {
          l = this.widthTarget.value
        } else if (this.widthTarget.value.toLowerCase().indexOf('h') !== -1) {
          h = this.widthTarget.value
        } else if (this.widthTarget.value.toLowerCase().indexOf('lbs') !== -1) {
          weight = this.widthTarget.value
        }

        if (this.heightTarget.value.toLowerCase().indexOf('l') !== -1) {
          l = this.heightTarget.value
        } else if (this.heightTarget.value.toLowerCase().indexOf('w') !== -1) {
          w = this.heightTarget.value
        } else if (this.heightTarget.value.toLowerCase().indexOf('lbs') !== -1) {
          weight = this.heightTarget.value
        }

        if (l) {
          this.lengthTarget.value = l
        }
        if (w) {
          this.widthTarget.value = w
        }
        if (h) {
          this.heightTarget.value = h
        }
        if (weight) {
          this.weightTarget.value = weight
        }

        this.lengthTarget.value = this.lengthTarget.value.replace(/\D/g,'')
        this.widthTarget.value = this.widthTarget.value.replace(/\D/g,'')
        this.heightTarget.value = this.heightTarget.value.replace(/\D/g,'')
        this.weightTarget.value = this.weightTarget.value.replace(/\D/g,'')

        if (this.weightTarget.value.length > 0) {
            this.forcedClassTarget.focus()
        } else if (this.heightTarget.value.length > 0) {
            this.heightTarget.focus()
        }
    }
}
