module boiler.model;

import std.algorithm;
import vibe.http.server;

import boiler.HttpRequest;

alias Request_delegate = void delegate(HttpRequest req, HTTPServerResponse res);

struct Model_method {
	//List of access rights allowed to use method
	string[] access;
	Request_delegate method;

	void call(HttpRequest req, HTTPServerResponse res, string[] user_access = []) {
		//If any access matches any user_access, call method, else error.
		//A method with empty access list is considered public.
		if(access.length == 0 || findAmong(access, user_access).length > 0) {
			method(req, res);
		}
		else {
			res.writeJsonBody("User has no access to method.");
		}
	}
}
