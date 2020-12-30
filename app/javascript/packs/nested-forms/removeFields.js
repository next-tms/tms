class removeFields {

    constructor() {
        this.links = document.querySelectorAll('.remove-fields');
        this.iterateLinks();
    }

    iterateLinks() {
        if (this.links.length === 0) return;
        this.links.forEach((link) => {
            link.addEventListener('click', (e) => {
                this.handleClick(link, e);
            });
        });
    }

    handleClick(link, e) {
        if (!link || !e) return;
        e.preventDefault();
        let fieldParent = link.closest('.nested-fields');
        let deleteField = fieldParent ? fieldParent.querySelector('input[type="hidden"]') : null
        if (deleteField) {
            deleteField.value = 'true';
            fieldParent.style.display = 'none';
        }
    }

}

window.addEventListener('turbolinks:load', () => new removeFields());