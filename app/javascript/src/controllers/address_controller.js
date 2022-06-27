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

    fillCityAndStateByZipCode(event) {
        event.preventDefault();

        console.log(event.target)
        let zipCode = event.target.value;
        let textField = event.target
        let elementId = textField.id
        let helpText = textField.parentElement.lastElementChild
        let countrySelect = document.getElementById(elementId.replace('zip_code', "country_id"))
        let selectedCountry = countrySelect.options[countrySelect.selectedIndex].innerHTML;
        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        var duration = 1000;

        let data = { zip_code: zipCode, country: selectedCountry }


        if (zipCode == null || zipCode == "") {
            return
        }

        clearTimeout(textField._timer);
        textField._timer = setTimeout(()=>{
            helpText.innerHTML = "Searching for Location based on ZIP..."
            fetch('/fetch_details_by_zip_code', {
                method: 'POST',
                headers: {
                  'Accept': 'text/javascript',
                  'Content-Type': 'application/json',
                  'X-CSRF-Token': authenticityToken
                },
                body: JSON.stringify(data),
            })
            .then(response => response.json())
            .then(function(data) {
                setTimeout(()=>{
                    console.log(data)
                    if (data.error == null) {
                        document.getElementById(elementId.replace("zip_code", "city")).value = data.city;
                        var stateSelect = document.getElementById(elementId.replace("zip_code", "region_id"))
                        Array.from(stateSelect.options).forEach(function(option) {
                            if (option.text ===  data.state) {
                              option.selected = true
                            }
                        })

                        helpText.innerHTML = "Location Found, City and State are Filled!"
                    } else {
                        helpText.innerHTML = "No Location Found based on ZIP"
                    }
                }, duration)

            })
        }, 500);
    }
}
