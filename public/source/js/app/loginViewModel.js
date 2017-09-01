var loginViewModel = function() {
	var self = this;
	self.username = '';
	self.password = '';
	self.sign_in = function() {
		var data = ko.toJS(this);
		data.model = "user";
		data.action = "Login";
		ajax_post(data, function(returnedData) {
			console.log(returnedData);
		    if(returnedData.success == true) {
	    		window.location.href = window.location.href;
		    }
		});
	};

	self.sign_up = function() {
		var data = ko.toJS(this);
		data.action = "CreateUser";
		ajax_post(data, function(returnedData) {
			console.log(returnedData);
			if(returnedData == true) {
				loginViewModel.sign_in();
			}
		});
	};

	self.search = ko.observable('');

	self.search.subscribe(function (newText) {
		ajax_post({
			action: "FindCity",
			search: newText
		}, function(returnedData) {
			console.log(returnedData);
		});
	});
};

ko.applyBindings(new loginViewModel());