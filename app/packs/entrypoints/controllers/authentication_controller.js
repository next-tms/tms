import { Controller } from "stimulus"

export default class extends Controller {
    signout(e) {
        e.preventDefault

        const authenticityToken = document.querySelector('meta[name="csrf-token"]').content
        const url = e.currentTarget.href

        fetch(url, {
            credentials: 'include',
            method: 'DELETE',
            headers: {
              'X-CSRF-Token': authenticityToken
            }
        })
        .then(response => {
            Turbo.visit('/')
        })
    }
}
