import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ 'country' ]

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
            .then(function(data) {
                if (!data.country) {
                    return
                }

                console.log(data.country.regions)
            })
    }
}
