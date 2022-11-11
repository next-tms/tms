import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ 'form', 'brokerCustomer', 'shipperAddress' ]

    handle(e) {
        console.log('Not implemented')
        return

        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        const id = this.brokerCustomerTarget.options[this.brokerCustomerTarget.selectedIndex].value
        const shipperName = this.brokerCustomerTarget.options[this.brokerCustomerTarget.selectedIndex].textContent

        const url = '/broker/customers/' + id + '/primary-pickup-address.json'

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
                if (!data.primary_pickup_address) {
                    return
                }

                document.querySelector('input[name="shipment[shipper_name]"]').value = shipperName

                const primaryPickupAddress = data['primary_pickup_address']
                const shipperAddressQuery = '[name="shipment[shipper_address_attributes]'
                console.log(primaryPickupAddress)
                document.querySelector('input' + shipperAddressQuery + '[street]"]').value = primaryPickupAddress.street
                document.querySelector('input' + shipperAddressQuery + '[city]"]').value = primaryPickupAddress.city
                document.querySelector('select' + shipperAddressQuery + '[state]"]').selectedIndex = primaryPickupAddress.state
                document.querySelector('input' + shipperAddressQuery + '[zip_code]"]').selectedIndex = primaryPickupAddress.zip_code
                document.querySelector('select' + shipperAddressQuery + '[country_id]"]').selectedIndex = primaryPickupAddress.country_id
            })
    }
}
