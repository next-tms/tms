import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        'city',
        'country',
        'regions',
        'field',
        'postalCode',
        'validateAddressLoading',
        'validateAddressFailed',
        'validateAddressSuccess'
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
      let hasFilledAddress = this.fieldTargets.every(field => field.value || field.closest('[hidden]')) &&!!this.countryTarget.value && !!this.regionsTarget.value

      if (hasFilledAddress) {
        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        let success = this.validateAddressSuccessTarget;
        let failed = this.validateAddressFailedTarget;
        let loading = this.validateAddressLoadingTarget;

        success.classList.add('d-none')
        failed.classList.add('d-none')
        loading.classList.remove('d-none')

        let street = this.fieldTargets.find(field => field.id.includes('_street')).value
        let zip = this.fieldTargets.find(field => field.id.includes('_zip')).value
        let city = this.fieldTargets.find(field => field.id.includes('_city')).value

        let data = { city: city, country_alpha2: this.countryTarget.value, region_iso31662: this.regionsTarget.value, street: street, zip_code: zip }

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

        this.postalCodeRegion = null

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
            .then(response => {
                if (this.countryTarget.value != country_alpha2) {
                    return
                }

                this.populateRegions(response.country)
                this.updatePostalCodes(response.country)
                this.loadedCountry = country_alpha2

                if (this.pendingPostalCode) {
                    const input = this.pendingPostalCode
                    this.pendingPostalCode = null
                    this.lookUpPostalCode(input)
                }
            })
    }

    postalCodeTargetConnected(input) {
        input.addEventListener('change', () => {
            input.value = input.value.toUpperCase()
            this.applyPostalCodePattern(input)
            this.lookUpPostalCode(input)
        })
    }

    savedCountry() {
        return Array.from(this.countryTarget.options).find(option => option.defaultSelected)?.value
    }

    applyPostalCodePattern(input) {
        const saved = input.value.toUpperCase() == input.defaultValue.toUpperCase() && this.countryTarget.value == this.savedCountry()

        if (this.postalCodeFormat && !saved) {
            input.pattern = this.postalCodeFormat
        } else {
            input.removeAttribute('pattern')
        }
    }

    regionsTargetConnected(select) {
        select.addEventListener('change', () => this.alertRegionMismatch(select))
    }

    lookUpPostalCode(input) {
        this.postalCodeRegion = null

        if (this.loadedCountry != this.countryTarget.value) {
            this.pendingPostalCode = input
            return
        }

        if (!input.value || input.validity.patternMismatch) {
            return
        }

        const country = this.countryTarget.value
        const postalCode = input.value
        const url = '/countries/' + country + '/postal_codes/' + encodeURIComponent(postalCode) + '.json'

        fetch(url, { credentials: 'include', headers: { 'Accept': 'application/json' } })
            .then(response => response.ok ? response.json() : null)
            .then(response => {
                if (response && this.countryTarget.value == country && input.value == postalCode) {
                    this.postalCodeLookup = { country: country, postalCode: postalCode }
                    this.fillFromPostalCode(response.postal_code)
                }
            })
    }

    fillFromPostalCode(postalCode) {
        if (this.hasCityTarget && postalCode.city) {
            this.cityTarget.value = postalCode.city
        }

        if (postalCode.region_iso31662) {
            this.postalCodeRegion = postalCode.region_iso31662
        }

        if (!this.applyPostalCodeRegion() && this.hasCityTarget) {
            this.cityTarget.dispatchEvent(new Event('change'))
        }
    }

    postalCodeRegionCurrent() {
        return !!this.postalCodeRegion &&
            this.postalCodeLookup?.country == this.countryTarget.value &&
            this.postalCodeLookup?.postalCode == this.postalCodeTarget.value
    }

    applyPostalCodeRegion() {
        const select = this.regionsTarget

        if (!this.postalCodeRegionCurrent() || select.value == this.postalCodeRegion) {
            return false
        }

        if (!Array.from(select.options).some(option => option.value == this.postalCodeRegion)) {
            return false
        }

        select.value = this.postalCodeRegion
        select.dispatchEvent(new Event('change'))

        return true
    }

    alertRegionMismatch(select) {
        if (!this.postalCodeRegionCurrent() || select.value == this.postalCodeRegion) {
            return
        }

        const region = select.selectedOptions[0]?.text
        window.alert(this.postalCodeLabel + ' ' + this.postalCodeTarget.value + ' is not in ' + region + '.')
    }

    updatePostalCodes(country) {
        if (country.postal_code === undefined) {
            return
        }

        this.postalCodeFormat = country.postal_code_format
        this.postalCodeLabel = country.postal_code_label

        this.postalCodeTargets.forEach((input) => {
            const formGroup = input.closest('.mb-3') || input

            formGroup.hidden = !country.postal_code
            input.required = country.postal_code

            if (!country.postal_code) {
                input.value = ''
            } else if (this.countryTarget.value != this.savedCountry()) {
                input.value = input.value.toUpperCase()
            }

            input.labels.forEach(label => label.textContent = country.postal_code_label)

            if (input.hasAttribute('placeholder')) {
                input.placeholder = country.postal_code_label
            }

            this.applyPostalCodePattern(input)

            if (country.alpha2 == 'US') {
                input.inputMode = 'numeric'
                input.removeAttribute('autocapitalize')
            } else {
                input.removeAttribute('inputmode')
                input.autocapitalize = 'characters'
            }
        })
    }

    populateRegions(country) {
        const selected_option = this.regionsTarget.options[this.regionsTarget.selectedIndex]
        const selected_value = selected_option ? selected_option.value : ''

        Array.from(this.regionsTarget.options).forEach(function(option) {
            option.remove()
        })

        // Keep a saved region that Grid no longer returns, so saving the form does not change it
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

        this.applyPostalCodeRegion()
    }
}
