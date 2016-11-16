var loginViewModel = {
	username: '',
	password: '',
	sign_in : function() {
		var data = ko.toJS(this);
		data.model = "user";
		data.method = "login_password";
		ajax_post(data, function(returnedData) {
			console.log(returnedData);
		    if(returnedData == true) {
	    		window.location.href = window.location.href;
		    }
		});
	},
	sign_up : function() {
		var data = ko.toJS(this);
		data.model = "user";
		data.method = "create_user";
		ajax_post(data, function(returnedData) {
			console.log(returnedData);
		    if(returnedData == true) {
		    	loginViewModel.sign_in();
		    }
		});
	}
};

ko.applyBindings(loginViewModel);