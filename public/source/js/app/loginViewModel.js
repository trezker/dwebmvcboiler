var loginViewModel = {
	username: '',
	password: '',
	sign_in : function() {
		var data = ko.toJS(this);
		data.model = "user";
		data.action = "Login";
		ajax_post(data, function(returnedData) {
			console.log(returnedData);
		    if(returnedData.success == true) {
	    		window.location.href = window.location.href;
		    }
		});
	},
	sign_up : function() {
		var data = ko.toJS(this);
		data.action = "CreateUser";
		ajax_post(data, function(returnedData) {
			console.log(returnedData);
		    if(returnedData == true) {
		    	loginViewModel.sign_in();
		    }
		});
	}
};

ko.applyBindings(loginViewModel);