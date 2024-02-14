import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

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
      let targetContainer = this.ratesContainerTargets.find(c => c.id == "rates_" + data.declared_freight_classes)
      targetContainer.innerHTML = targetContainer.innerHTML += data.html

      var rates = Array.from(targetContainer.children)
      var validRates = rates.filter(r => r.dataset.cost)
      var apiErroRates = rates.filter(r => r.dataset.cost == undefined)
  
      // Sort Rates by Cost and append HTML by lowest to highest Cost
      if (validRates.length != 0) {
        var sortedRates = validRates.sort(function (a, b) {
          return Number(a.dataset.cost) - Number(b.dataset.cost);
        })
  
        targetContainer.innerHTML = sortedRates.map(sortedRate => sortedRate.outerHTML).join('')
      }
   
      // Append Rates with API Errors after appending the Valid Rates
      if (apiErroRates.length != 0) {
        targetContainer.innerHTML = targetContainer.innerHTML += apiErroRates.map(errorRate => errorRate.outerHTML).join('')
      }
    } else if (data.finished) {
        this.loadingTarget.classList.add('d-none')
    }
  }
}