module boiler.model;

import std.algorithm;
import vibe.http.server;

import boiler.HttpRequest;
import boiler.HttpResponse;

alias Request_delegate = HttpResponse delegate(HttpRequest req);

struct Model_method {
	//List of access rights allowed to use method
	string[] access;
	Request_delegate method;

	HttpResponse call(HttpRequest req, string[] user_access = []) {
		//If any access matches any user_access, call method, else error.
		//A method with empty access list is considered public.
		HttpResponse res;
		if(access.length == 0 || findAmong(access, user_access).length > 0) {
			res = method(req);
		}
		else {
			res = new HttpResponse;
			res.writeBody("User has no access to method.", 200);
		}
		return res;
	}
}
