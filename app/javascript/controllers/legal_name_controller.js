import { Controller } from "@hotwired/stimulus"

const DBA = /[\s,]+(?:d\.?\s?b\.?\s?a\.?|d\/b\/a)\s+/i
const SMALL_WORDS = [ 'a', 'an', 'and', 'at', 'by', 'for', 'in', 'of', 'on', 'the', 'to' ]
const SUFFIX = /[\s,]+(?:co|corp|corporation|inc|incorporated|l\.?l\.?c|l\.?l\.?p|l\.?p|ltd|p\.?c|p\.?l\.?l\.?c)\.?$/i

export default class extends Controller {
    static targets = [ 'legalName', 'name' ]

    connect() {
        this.previousLegalName = this.legalNameTarget.value
    }

    fill() {
        const name = this.nameTarget.value
        const previousLegalName = this.previousLegalName

        this.previousLegalName = this.legalNameTarget.value

        if (name !== '' && name !== previousLegalName && name !== this.suggest(previousLegalName)) return

        this.nameTarget.value = this.suggest(this.legalNameTarget.value)
    }

    suggest(legalName) {
        let name = legalName.split(DBA).pop().trim()

        while (SUFFIX.test(name)) name = name.replace(SUFFIX, '').trim()

        name = name.replace(/,$/, '').trim()

        name = /[a-z]/.test(name) ? name : this.titleize(name)

        return name.replace(/\b(?:[A-Z]\.){2,}/g, initials => initials.replaceAll('.', ''))
    }

    titleize(name) {
        return name.split(/\s+/).map((word, index) => {
            const lower = word.toLowerCase()

            if (index > 0 && SMALL_WORDS.includes(lower)) return lower
            if (/^[A-Z]{2,4}$/.test(word) && !/[AEIOUY]/.test(word)) return word

            return lower.replace(/(^|[-\/.])([a-z])/g, (_match, separator, letter) => separator + letter.toUpperCase())
        }).join(' ')
    }
}
