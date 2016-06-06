function create_testuser(callback) {
	ajax_post_sync({
		'model': 'user', 
		'method': 'create_user',
		'password': 'testpass',
		'username': 'testuser'
	}, callback);
}

function delete_testuser(callback) {
	ajax_post_sync({
		'model': 'user', 
		'method': 'delete_user',
		'username': 'testuser'
	}, callback);
}

function login_testuser(callback) {
	ajax_post_sync({
		'model': 'user', 
		'method': 'login_password',
		'password': 'testpass',
		'username': 'testuser'
	}, callback);
}

function test_logout() {
	ajax_post_sync({
		'model': 'user', 
		'method': 'logout'
	}, function(data) {
		test_assert(data == true);
		ajax_post_sync({
			'model': 'user', 
			'method': 'get_current_user_id'
		}, function(data) {
			test_assert(data == false);
		});
	});
}

function test_login_password() {
	create_testuser(function(data) {
		test_assert(data == true);
		login_testuser(function(data) {
			test_assert(data == true);
			ajax_post_sync({
				'model': 'user', 
				'method': 'get_current_user_id'
			}, function(data) {
				test_assert(data != false);
				delete_testuser(function(data) {
					test_assert(data == true);
				});
			});
		});
	});
}

function test_invalid_login_password() {
	create_testuser(function(data) {
		test_assert(data == true);
		ajax_post_sync({
			'model': 'user', 
			'method': 'login_password',
			'password': 'testass',
			'username': 'testuser'
		}, function(data) {
			test_assert(data == false);
			ajax_post_sync({
				'model': 'user', 
				'method': 'get_current_user_id'
			}, function(data) {
				test_assert(data == false);
				delete_testuser(function(data) {
					test_assert(data == true);
				});
			});
		});
	});
}

//Bugfix: Session already started caused crash when logging in twice.
//Security: Make sure session is cleared if a second login is attempted.
function test_double_login() {
	create_testuser(function(data) {
		test_assert(data == true);
		login_testuser(function(data) {
			test_assert(data == true);
			login_testuser(function(data) {
				test_assert(data == false);
				ajax_post_sync({
					'model': 'user', 
					'method': 'get_current_user_id'
				}, function(data) {
					test_assert(data == false);
					delete_testuser(function(data) {
						test_assert(data == true);
					});
				});
			});
		});
	});
}

function test_unique_username() {
	create_testuser(function(data) {
		test_assert(data == true);
		create_testuser(function(data) {
			test_assert(data == false);
			delete_testuser(function(data) {
				test_assert(data == true);
			});
		});
	});
}

run_test_suite([
	test_logout, 
	test_invalid_login_password, 
	test_login_password,
	test_unique_username
]);
