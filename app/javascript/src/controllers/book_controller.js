import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    handle(e) {
        e.preventDefault

        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        const url = e.currentTarget.dataset.url

        console.log(e.currentTarget.dataset)
        console.log(e.currentTarget.dataset.appliedRateUid)

        const data = {
            authenticity_token: authenticityToken,
            shipment: {
                applied_rate_uid: e.currentTarget.dataset.appliedRateUid,
                booked_at: new Date(),
                quote_only: false
            }
        }

        fetch(url, {
            credentials: 'include',
            method: 'PATCH',
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-CSRF-Token': authenticityToken
            },
            body: JSON.stringify(data)
        })
        .then(response => response.json())
        .then(data => window.Turbo.visit(data.location))
    }
}
