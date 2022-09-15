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
}
