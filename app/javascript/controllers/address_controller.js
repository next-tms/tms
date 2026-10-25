import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        'country',
        'regions',
        'field',
        'validateAddressLoading',
        'validateAddressFailed',
        'validateAddressSuccess',
        'standardizedAddressId'
    ]

    connect(e) {
        this.handle()

        if (this.hasFieldTarget && this.hasCountryTarget && this.hasRegionsTarget) {
            this.fieldTargets.concat([this.countryTarget, this.regionsTarget]).forEach((input) => {
                input.addEventListener('change', this.validateAddress.bind(this))
            })
        }
    }

    validateAddress() {
      let hasFilledAddress = this.fieldTargets.every(select => select.value) && !!this.countryTarget.value && !!this.regionsTarget.value

      if (hasFilledAddress) {
        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        let success = this.validateAddressSuccessTarget;
        let failed = this.validateAddressFailedTarget;
        let loading = this.validateAddressLoadingTarget;
        let standardizedAddressId = this.standardizedAddressIdTarget;

        success.classList.add('d-none')
        failed.classList.add('d-none')
        loading.classList.remove('d-none')

        let street = this.fieldTargets.find(field => field.id.includes('_street')).value
        let zip = this.fieldTargets.find(field => field.id.includes('_zip')).value
        let city = this.fieldTargets.find(field => field.id.includes('_city')).value

        let data = { street: street, city: city, zip_code: zip, region_iso31662: this.regionsTarget.value }

        fetch('/validate_address', {
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
                loading.classList.add('d-none')

                if (data.error == null) {
                    let id = data.standardized_address_id
                    standardizedAddressId.value = id;
                    success.classList.remove('d-none')
                } else {
                    failed.classList.remove('d-none')
                }
            }, 1000)

        })
      }
    }

    handle(e) {
        if (this.countryTarget === undefined || this.regionsTarget === undefined) {
            return;
        }

        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        const country_alpha2 = this.countryTarget.options[this.countryTarget.selectedIndex].value

        const url = '/countries/' + country_alpha2 + '.json'

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
        const selected_option = this.regionsTarget.options[this.regionsTarget.selectedIndex]
        const selected_value = selected_option ? selected_option.value : ''

        Array.from(this.regionsTarget.options).forEach(function(option) {
            option.remove()
        })

        // Keep a saved region that Transponder no longer returns, so saving the form does not change it
        if (selected_value.startsWith(country.alpha2 + '-') && !country.regions.some(region => region.id == selected_value)) {
            selected_option.selected = true
            this.regionsTarget.add(selected_option)
        }

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

        let zipCode = event.target.value;
        let textField = event.target
        let elementId = textField.id
        let helpText = textField.parentElement.lastElementChild
        let countrySelect = document.getElementById(elementId.replace('zip_code', "country_alpha2"))
        let selectedCountry = countrySelect.options[countrySelect.selectedIndex].innerHTML;
        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        var duration = 1000;

        let data = { postal_code: zipCode, country: selectedCountry }


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
                        var stateSelect = document.getElementById(elementId.replace("zip_code", "region_iso31662"))
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
