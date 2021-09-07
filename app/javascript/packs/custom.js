document.addEventListener('turbolinks:load', function() {

    Date.prototype.addHours = function(h) {
        this.setHours(this.getHours() + h);
        return this;
    }

    if ($('body').hasClass('auto-refresh')) {
        // Not yet working
    }

    function moneyHandler() {
        $('input.money').blur(function() {
            num = $(this).val();
            num = num.replace(/[^\d.-]/g, '');
            num = parseFloat(num);
            num = num.toFixed(2);
            if (isNaN(num)) {
                $(this).val('0.00');
            } else {
                $(this).val(num);
            }
        });
    }
    moneyHandler();

    $(document).on('change', function() {
        moneyHandler();
    });

    $('.clear-flatpickr').on('click', function() {
        $(this).parent().parent().parent().find('.flatpickr-input').val('');
        $(this).parent().parent().parent().find('.input').val('');
        return false;
    });

    $('input.flatpickr').flatpickr({
        defaultDate: $(this).val(),
        enableTime: true,
        time_24hr: false,
        dateFormat: 'Y-m-d H:i',
        minuteIncrement: 1,
        allowInput: false,
        altInput: true,
        altFormat: 'n/j/y h:i K'
    });

    $('input.flatpickr-datetime-max-today').flatpickr({
        defaultDate: $(this).val(),
        enableTime: true,
        time_24hr: false,
        dateFormat: 'Y-m-d H:i',
        minuteIncrement: 1,
        allowInput: false,
        altInput: true,
        altFormat: 'n/j/y h:i K',
        maxDate: new Date().addHours(12)
    });

    $('input.flatpickr-date').flatpickr({
        defaultDate: $(this).val(),
        enableTime: false,
        time_24hr: false,
        dateFormat: 'Y-m-d',
        minuteIncrement: 1,
        allowInput: false,
        altInput: true,
        altFormat: 'n/j/y'
    });

    $('input.flatpickr-date-max-today').flatpickr({
        defaultDate: $(this).val(),
        enableTime: false,
        time_24hr: false,
        dateFormat: 'Y-m-d',
        minuteIncrement: 1,
        allowInput: false,
        altInput: true,
        altFormat: 'n/j/y',
        maxDate: new Date().addHours(12)
    });

    $('textarea.copyable').click(function() {
        $(this).select();
        document.execCommand('copy');
    });

    $('.alert-dismiss-automatically').delay(1500).fadeOut(500, function() {
        $('alert-dismiss-automatically').alert('close');
    });

    $(document).on('scroll', function() {
        if ($(document).scrollTop() > 100) {
            $('.shrinkable').addClass('shrink');
        } else {
            $('.shrinkable').removeClass('shrink');
        }
    });

    $('tr[data-link]').click(function() {
        window.location = $(this).data('link');
    });

    $('form').on('click', '.remove-fields', function(e) {
        $(this).prev('input[type=hidden]').val('true');
        $(this).closest('.nested-fields').hide();
        return e.preventDefault();
    });

    function bindLengthFieldHandler() {
        console.log('bindLengthFieldHandler()');
        $('#shipment-form').on('change', function() {
            console.log('#shipment-form on change');
            $("[id$='_l']").on('blur', function() {
                console.log($(this).val().toLowerCase().indexOf('x'));
                if ($(this).val().toLowerCase().indexOf('x') > -1) {
                    dimensions = $(this).val().toLowerCase().split('x');
                    if (dimensions.length >= 2) {
                        // Let's get crazy
                        length_input = $(this);
                        length_input.val($.trim(dimensions[0]));
                        width_input = length_input.parent().find("[id$='_w']");
                        height_input = length_input.parent().find("[id$='_h']");
                        weight_input = length_input.parent().find("[id$='_weight']");
                        nmfc_input = length_input.parent().find("[id$='_nmfc']");
                        width_input.val($.trim(dimensions[1]));
                        if (dimensions.length == 3) {
                            if (dimensions[2].indexOf(' ') && dimensions[2].toLowerCase().indexOf('lbs')) {
                                height_and_weight = $.trim(dimensions[2]).split(' ');
                                console.log(height_and_weight);
                                var weight = height_and_weight[height_and_weight.length - 1]
                                height_input.val($.trim(height_and_weight[0]));
                                weight_input.val($.trim(weight.toLowerCase().replace('lbs', '')));
                                nmfc_input.focus();
                            } else {
                                height_input.val($.trim(dimensions[2]));
                                weight_input.focus();
                            }
                        } else {
                            height_input.focus();
                        }
                    }
                }
            });
        });
    }
    bindLengthFieldHandler();

    // Turbolinks prefetching from https://gist.github.com/hopsoft/ab500a3b584e2878c83137cb539abb32
    const hoverTime = 200;
    const fetchers = {}
    const doc = document.implementation.createHTMLDocument('prefetch')

    function fetchPage(url, success) {
        const xhr = new XMLHttpRequest()
        xhr.open('GET', url)
        xhr.setRequestHeader('VND.PREFETCH', 'true')
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) return
            success(xhr.responseText)
        }
        xhr.send()
    }

    function prefetchTurbolink(url) {
        fetchPage(url, responseText => {
            doc.open()
            doc.write(responseText)
            doc.close()
            const snapshot = Turbolinks.Snapshot.fromHTMLElement(doc.documentElement)
            Turbolinks.controller.cache.put(url, snapshot)
        })
    }

    function prefetch(url) {
        if (prefetched(url)) return
        prefetchTurbolink(url)
    }

    function prefetched(url) {
        return location.href === url || Turbolinks.controller.cache.has(url)
    }

    function prefetching(url) {
        return !!fetchers[url]
    }

    function cleanup(event) {
        const element = event.target
        clearTimeout(fetchers[element.href])
        element.removeEventListener('mouseleave', cleanup)
    }

    document.addEventListener('mouseover', event => {
        if (!event.target.dataset.prefetch) return
        const url = event.target.href
        if (prefetched(url)) return
        if (prefetching(url)) return
        cleanup(event)
        event.target.addEventListener('mouseleave', cleanup)
        fetchers[url] = setTimeout(() => prefetch(url), hoverTime)
    });

});