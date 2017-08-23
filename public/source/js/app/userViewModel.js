var userViewModel = {
	sign_out : function() {
		var data = {};
		data.action = "Logout";
		ajax_post(data, function(returnedData) {
		    if(returnedData.success == true) {
	    		window.location.href = window.location.href;
		    }
		});
	}
};

ko.applyBindings(userViewModel);