import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    fillCustomerAddressByBrokerCustomerId(event) {
        event.preventDefault();

        this.updateDispatcher(event);

        console.log(event.target)

        let brokerCustomerId = event.target.value;
        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        let data = { broker_customer_id: brokerCustomerId }

        fetch('/fetch_address_by_broker_customer', {
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
            console.log(data)
            if (data.error == null) {

                document.getElementById('shipment_shipper_address_attributes_street').value = data.street
                document.getElementById('shipment_shipper_address_attributes_street2').value = data.street2
                document.getElementById('shipment_shipper_address_attributes_city').value = data.city
                document.getElementById('shipment_shipper_address_attributes_zip_code').value = data.zip_code
                var stateSelect = document.getElementById('shipment_shipper_address_attributes_region_iso31662')
                Array.from(stateSelect.options).forEach(function(option) {
                    if (option.value === data.region_iso31662) {
                        option.selected = true
                    }
                })
            }

        })
    }

    updateDispatcher(e) {
        const dispatcherString = document.getElementById('customerDispatcherIds').dataset.customerDispatcherIds
        const dispatcherIdArr = dispatcherString.split(',')

        let brokerCustomerSelectedIndex = e.currentTarget.selectedIndex
        let applicableDispatcherId = dispatcherIdArr[brokerCustomerSelectedIndex]

        let dispatcherSelectTag = document.getElementById('shipment_dispatcher_id')
        dispatcherSelectTag.value = Number(applicableDispatcherId);


    }

    switchAddresses(e) {
        e.preventDefault()

        var shipperStreet = document.getElementById('shipment_shipper_address_attributes_street')
        var shipperStreet2 = document.getElementById('shipment_shipper_address_attributes_street2')
        var shipperCity = document.getElementById('shipment_shipper_address_attributes_city')
        var shipperRegion = document.getElementById('shipment_shipper_address_attributes_region_iso31662')
        var shipperZip = document.getElementById('shipment_shipper_address_attributes_zip_code')
        var shipperCountry = document.getElementById('shipment_shipper_address_attributes_country_alpha2')

        var shipperStreetValue = shipperStreet.value
        var shipperStreet2Value = shipperStreet2.value
        var shipperCityValue = shipperCity.value
        var shipperRegionValue = shipperRegion.value
        var shipperZipValue = shipperZip.value
        var shipperCountryValue = shipperCountry.value

        var receiverStreet = document.getElementById('shipment_receiver_address_attributes_street')
        var receiverStreet2 = document.getElementById('shipment_receiver_address_attributes_street2')
        var receiverCity = document.getElementById('shipment_receiver_address_attributes_city')
        var receiverRegion = document.getElementById('shipment_receiver_address_attributes_region_iso31662')
        var receiverZip = document.getElementById('shipment_receiver_address_attributes_zip_code')
        var receiverCountry = document.getElementById('shipment_receiver_address_attributes_country_alpha2')

        var receiverStreetValue = receiverStreet.value
        var receiverStreet2Value = receiverStreet2.value
        var receiverCityValue = receiverCity.value
        var receiverRegionValue = receiverRegion.value
        var receiverZipValue = receiverZip.value
        var receiverCountryValue = receiverCountry.value

        var shipperRegionOptions = shipperRegion.innerHTML
        shipperRegion.innerHTML = receiverRegion.innerHTML
        receiverRegion.innerHTML = shipperRegionOptions

        shipperStreet.value = receiverStreetValue
        shipperStreet2.value = receiverStreet2Value
        shipperCity.value = receiverCityValue
        shipperRegion.value = receiverRegionValue
        shipperZip.value = receiverZipValue
        shipperCountry.value = receiverCountryValue

        receiverStreet.value = shipperStreetValue
        receiverStreet2.value = shipperStreet2Value
        receiverCity.value = shipperCityValue
        receiverRegion.value = shipperRegionValue
        receiverZip.value = shipperZipValue
        receiverCountry.value = shipperCountryValue

        shipperCountry.dispatchEvent(new Event('change'))
        receiverCountry.dispatchEvent(new Event('change'))
    }
}
