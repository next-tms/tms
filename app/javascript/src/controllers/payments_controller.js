import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    updatePaymentMethod(e) {
        const bankDataString = document.getElementById('bankData').dataset.bankPaymentMethodIds
        const bankDataArr = Array.from(bankDataString)

        let bankSelectedIndex = e.currentTarget.selectedIndex
        let applicablePaymentMethodId = bankDataArr[bankSelectedIndex]

        let paymentMethodSelectTag = document.getElementById('payment_payment_method_id')

        paymentMethodSelectTag.value = applicablePaymentMethodId;
    }

    showDuePaymentTransactions(e) {
        let brokerCarrierId = document.getElementById('broker_carrier_id').value
        let cutOffDate = document.getElementById('cutoff_date').value
        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content

        if (!!brokerCarrierId && !!cutOffDate) {
            let data = { broker_carrier_id: brokerCarrierId, cutoff_date: cutOffDate }

            fetch('/broker/payment/due_payment_transactions', {
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
                let messageDiv = document.getElementById('paymentTransactionMessage')

                if (data.payment_transactions_count != 0) {
                    document.getElementById('formSubmit').classList.remove('d-none')

                    messageDiv.classList.remove('d-none')
                    messageDiv.classList.remove('alert-danger')
                    messageDiv.classList.add('alert-info')
                    messageDiv.innerHTML = "Found " + data.payment_transactions_count +
                                           " Unpaid Bill/s for " + data.broker_carrier_name +
                                           " that are due on or before " + data.date
                } else {
                    document.getElementById('formSubmit').classList.add('d-none')

                    messageDiv.classList.remove('d-none')
                    messageDiv.classList.remove('alert-info')
                    messageDiv.classList.add('alert-danger')
                    messageDiv.innerHTML = "No Unpaid Bills found for " + data.broker_carrier_name +
                                           " that are due on or before " + data.date
                }
            })
        }
    }
}
