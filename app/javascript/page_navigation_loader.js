var lastEvent = null

function hideSpinner() {
    document.getElementById('spinner').style.display = 'none';
    if (document.querySelector('#spinnerText') !== null ) {
        document.querySelector('#spinnerText').classList.add('d-none')
    }
}

function showSpinner() {
    document.getElementById('spinner').style.display = 'block';
}

document.addEventListener('turbo:load', function() {
  console.log('load')
  hideSpinner()
  lastEvent = 'load'
})

document.addEventListener('turbo:click', function() {
    console.log('click')
    showSpinner()
    lastEvent = 'click'
})

document.addEventListener('turbo:request-start', function() {
  console.log('request-start')
  showSpinner()
  lastEvent = 'request-start'
})

document.addEventListener('turbo:visit', function() {
  console.log('visit')
  showSpinner()
  lastEvent = 'visit'
})

document.addEventListener('turbo:request-end', function() {
  console.log('request-end')
  hideSpinner()
  lastEvent = 'request-end'
})

document.addEventListener('turbo:render', function() {
  console.log('render')
  hideSpinner()
  lastEvent = 'render'
})

document.addEventListener('submit', function() {
  console.log('load')
  showSpinner()
  lastEvent = 'submit'
})

document.addEventListener('turbo:submit-start', function() {
  console.log('submit-start')
  showSpinner()
  lastEvent = 'submit-start'
})

document.addEventListener('turbo:frame-load', function() {
  console.log('frame-load')
  hideSpinner()
  lastEvent = 'frame-load'
})

document.addEventListener('turbo:before-render', function() {
  console.log('before-render')
  hideSpinner()
  lastEvent = 'before-render'
})

document.addEventListener('turbo:before-fetch-response', function() {
  console.log('before-fetch-response')

  console.log('LAST EVENT ----' + lastEvent)
  if (lastEvent == 'submit-start') {
    hideSpinner()
  } else {
    setTimeout(function() {
      let spinner = document.querySelector('#spinner')

      if (spinner.style.display !== 'none') {
          document.querySelector('#spinnerText').classList.remove('d-none')
      }
    }, 3000)
  }

  lastEvent = 'before-fetch-response'
})

document.addEventListener('turbo:before-fetch-request', function() {
  console.log('before-fetch-request')
  showSpinner()
  if (lastEvent == 'click') {
      setTimeout(function() {
        let spinner = document.querySelector('#spinner')

        if (spinner.style.display !== 'none') {
            document.querySelector('#spinnerText').classList.remove('d-none')
        }
      }, 3000)
    }
  lastEvent = 'before-fetch-request'
})

document.addEventListener('ajax:send', function() {
  console.log('ajax:send')
  showSpinner()
})

document.addEventListener('ajax:complete', function() {
  console.log('ajax:complete')
  hideSpinner();

  setTimeout(() => hideSpinner(), 1500);
})
