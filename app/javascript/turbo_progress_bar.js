document.addEventListener("turbo:before-fetch-request", function(e) { //
  Turbo.navigator.delegate.adapter.showProgressBar();
})

document.addEventListener("turbo:frame-render", function(e) { //
  Turbo.navigator.delegate.adapter.progressBar.hide()
})