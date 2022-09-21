import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "attr" ]

    connect() {
        console.log(this.attrTarget)
        if (this.attrTarget !== null) {
            let attrName = this.attrTarget.dataset.attrName
            console.log(attrName)
            let element = document.getElementById(attrName)

            if ( element !== null ) {
                element.classList.add('bg-primary')
                element.classList.add('text-light')

                var links = Array.from(element.getElementsByTagName('a'))
                var inputs = Array.from(element.getElementsByTagName('input'))

                links.forEach(function(link) { link.classList.add('text-light') })
                inputs.forEach(function(input) { input.classList.add('text-primary') })

                if (element.offsetTop > window.innerHeight) {
                    setTimeout(() => {
                        element.scrollIntoView();
                    }, 1000)
                }
            }
        }
    }
}
