module application.application;

import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.model;

import application.user;

class Application {
	Mongo mongo;
	User_model user_model;

	bool initialize() {
		try {
			mongo = new Mongo("mongodb://localhost");
			user_model = new User_model;
		}
		catch(Exception e) {
			logInfo(e.msg);
			return false;
		}
	    return true;
	}

	void setup_models(ref Model_method[string][string] models) {
		user_model.setup(mongo, models);
	}

	string rewrite_path(HTTPServerRequest req) {
		if(!req.session) {
			return "/login";
		}
		return req.path;
	}
}
