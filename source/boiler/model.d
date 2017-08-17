module boiler.model;

import std.algorithm;
import vibe.http.server;

import boiler.HttpRequest;
import boiler.HttpResponse;

alias Request_delegate = void delegate(HttpRequest req, HttpResponse res);

struct Model_method {
	//List of access rights allowed to use method
	string[] access;
	Request_delegate method;

	void call(HttpRequest req, HttpResponse res, string[] user_access = []) {
		//If any access matches any user_access, call method, else error.
		//A method with empty access list is considered public.
		if(access.length == 0 || findAmong(access, user_access).length > 0) {
			method(req, res);
		}
		else {
			res.writeBody("User has no access to method.", 200);
		}
	}
}
