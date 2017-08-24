function ajax_post_ko(data, done) {
    $.ajax({
        method      : "POST",
        dataType    : 'json',
        contentType : 'application/json; charset=UTF-8',
        url: "/ajax/" + data.model + "/" + data.method,
        data: data
    })
    .success(done);
}

function ajax_post(data, done) {
	$.ajax({
		method		: "POST",
		dataType   	: 'json',
		contentType	: 'application/json; charset=UTF-8',
		url: "/ajax/" + data.action,
		data: JSON.stringify(data)
	})
	.success(done);
}

function ajax_html(url, done) {
	$.ajax({
		cache		: false,
		method		: "GET",
		dataType   	: 'html',
		contentType	: 'application/json; charset=UTF-8',
		url: url
	})
	.done(done);
}

function setup_ajax_form(form, done) {
	form.submit(function(event) {
		event.preventDefault();
		var formdata = $(this).serializeObject();
		$.ajax({
			method		: "POST",
			dataType   	: 'json',
			contentType	: 'application/json; charset=UTF-8',
			url: "/ajax",
			data: JSON.stringify(formdata)
		}).done(done);
	});
}

(function($){
    $.fn.serializeObject = function(){

        var self = this,
            json = {},
            push_counters = {},
            patterns = {
                "validate": /^[a-zA-Z][a-zA-Z0-9_]*(?:\[(?:\d*|[a-zA-Z0-9_]+)\])*$/,
                "key":      /[a-zA-Z0-9_]+|(?=\[\])/g,
                "push":     /^$/,
                "fixed":    /^\d+$/,
                "named":    /^[a-zA-Z0-9_]+$/
            };


        this.build = function(base, key, value){
            base[key] = value;
            return base;
        };

        this.push_counter = function(key){
            if(push_counters[key] === undefined){
                push_counters[key] = 0;
            }
            return push_counters[key]++;
        };

        $.each($(this).serializeArray(), function(){

            // skip invalid keys
            if(!patterns.validate.test(this.name)){
                return;
            }

            var k,
                keys = this.name.match(patterns.key),
                merge = this.value,
                reverse_key = this.name;

            while((k = keys.pop()) !== undefined){

                // adjust reverse_key
                reverse_key = reverse_key.replace(new RegExp("\\[" + k + "\\]$"), '');

                // push
                if(k.match(patterns.push)){
                    merge = self.build([], self.push_counter(reverse_key), merge);
                }

                // fixed
                else if(k.match(patterns.fixed)){
                    merge = self.build([], k, merge);
                }

                // named
                else if(k.match(patterns.named)){
                    merge = self.build({}, k, merge);
                }
            }

            json = $.extend(true, json, merge);
        });

        return json;
    };
})(jQuery);