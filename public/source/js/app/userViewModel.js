var userViewModel = {
	sign_out : function() {
		var data = {};
		data.model = "user";
		data.method = "logout";
		ajax_post(data, function(returnedData) {
		    if(returnedData == true) {
	    		window.location.href = window.location.href;
		    }
		});
	}
};

ko.applyBindings(userViewModel);