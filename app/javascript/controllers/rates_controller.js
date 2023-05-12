import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ['ratesContainer', 'loading'];

  connect() {
    this.subscriptions = consumer.subscriptions.create(
      {
        channel: 'RatesChannel',
        id: this.ratesContainerTarget.dataset.shipmentId
      },
      {
        connected: this._cableConnected.bind(this),
        disconnected: this._cableDisconnected.bind(this),
        received: this._cableReceived.bind(this),
      }
    );
  }

  _cableConnected() {
    // Called when the subscription is ready for use on the server
  }

  _cableDisconnected() {
    // Called when the subscription has been terminated by the server
  }

  _cableReceived(data) {
    // Called when there's incoming data on the websocket for this channel
    if (data.html) {
        let targetContainer = this.ratesContainerTargets.find(c => c.id == "rates_" + data.use_forced_freight_class)
        targetContainer.innerHTML = this.ratesContainerTarget.innerHTML += data.html
    } else if (data.finished) {
        this.loadingTarget.classList.add('d-none')
    }
  }
}