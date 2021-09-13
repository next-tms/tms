import { Controller } from 'stimulus'

export default class extends Controller {
    static targets = ['target', 'template']
    static values = {
        wrapperSelector: String,
        actionSelector: String
    }

    initialize() {
        this.wrapperSelector = this.wrapperSelectorValue || '.nested-form-wrapper'
        this.actionSelector = this.actionSelectorValue || '.nested-form-action'
    }

    add(e) {
        e.preventDefault()

        const actionSelector = e.target.closest(this.actionSelector)
        const insertHTML = (target, content) => {
            target.insertAdjacentHTML('beforebegin', content)
        }

        if (actionSelector) {
            const model = actionSelector.dataset.model
            const templateTarget = this.templateTargets.find(el => el.dataset.modelTemplate === model)
            const target = this.targetTargets.find(el => el.dataset.modelTarget === model)
            const content = templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
            insertHTML(target, content)
        } else {
            const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
            insertHTML(this.targetTarget, content)
        }
    }

    remove(e) {
        e.preventDefault()

        const wrapper = e.target.closest(this.wrapperSelector)

        if (wrapper.dataset.newRecord === 'true') {
            wrapper.remove()
        } else {
            wrapper.style.display = 'none'
            wrapper.querySelector("input[name*='_destroy']").value = 1
        }
    }
}
