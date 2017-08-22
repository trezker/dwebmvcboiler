module application.application;

import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.model;
import boiler.Ajax;

import application.UserCreator;
import application.Login;
import application.Logout;
import application.CurrentUser;

class Application {
	//Mongo mongo;
	//User_model user_model;

	bool initialize() {
		try {
			MongoPool pool = new MongoPool("mongodb://localhost");
			Mongo mongo = pool.pop;
			//user_model = new User_model;
		}
		catch(Exception e) {
			logInfo(e.msg);
			return false;
		}
	    return true;
	}

	void setup_models(ref Model_method[string][string] models) {
		//user_model.setup(mongo, models);
	}

	void SetupAjaxMethods(Ajax ajax) {
		ajax.SetAction("CreateUser", new UserCreator());
		ajax.SetAction("Login", new Login());
		ajax.SetAction("Logout", new Logout());
		ajax.SetAction("CurrentUser", new CurrentUser());
	}

	string rewrite_path(HTTPServerRequest req) {
		if(!req.session) {
			return "/login";
		}
		return req.path;
	}
}
