import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ['country', 'regions']

    connect(e) {
        this.handle()
    }

    handle(e) {
        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        const country_id = this.countryTarget.options[this.countryTarget.selectedIndex].value

        const url = '/countries/' + country_id + '.json'

        fetch(url, {
                credentials: 'include',
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': authenticityToken
                }
            })
            .then(response => response.json())
            .then(response => this.populateRegions(response.country))
    }

    populateRegions(country) {
        const selected_value = this.regionsTarget.options[this.regionsTarget.selectedIndex].value

        Array.from(this.regionsTarget.options).forEach(function(option) {
            option.remove()
        })

        country.regions.forEach(function(region) {
            const option = document.createElement('option')
            option.text = region.name
            option.value = region.id

            if (option.value == selected_value) {
                option.selected = true
            }

            this.regionsTarget.add(option)
        }.bind(this))
    }
}
