import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { dateStyle: { type: String, default: 'medium' }, locale: String, timeStyle: { type: String, default: 'short' }, timeZone: String }

    connect() {
        this.updateTime()
    }

    timeZoneValueChanged() {
        this.updateTime()
    }

    updateTime() {
        const isoDate = this.element.getAttribute('datetime')
        const date = new Date(isoDate)

        if (isNaN(date.getTime())) {
            console.warn(`Invalid ISO-8601 date: ${isoDate}`)
            return
        }

        const locale = this.localeValue || undefined
        const timeZone = this.timeZoneValue || undefined
        const timeStyle = this.timeStyleValue || undefined

        try {
            const localTime = new Intl.DateTimeFormat(locale, { dateStyle: this.dateStyleValue, timeStyle, timeZone }).format(date)

            if (!timeStyle) {
                this.element.textContent = localTime
                return
            }

            const timeZoneName = new Intl.DateTimeFormat(locale, { timeZoneName: 'short', timeZone })
                .formatToParts(date)
                .find((part) => part.type === 'timeZoneName')
                .value

            this.element.textContent = `${localTime} ${timeZoneName}`
        } catch (error) {
            console.warn(`Invalid time zone: ${timeZone}`, error)
        }
    }
}
