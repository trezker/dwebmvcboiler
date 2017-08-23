module application.application;

import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.model;
import boiler.Ajax;
import boiler.HttpRequest;

import application.database;
import application.storage.user;
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
		Database database = GetDatabase();
		auto userStorage = new User_storage(database);

		auto createUser = new UserCreator;
		createUser.setup(userStorage);
		ajax.SetAction("CreateUser", createUser);

		auto login = new Login;
		login.setup(userStorage);
		ajax.SetAction("Login", login);
		ajax.SetAction("Logout", new Logout);

		auto currentUser = new CurrentUser;
		currentUser.Setup(userStorage);
		ajax.SetAction("CurrentUser", currentUser);
	}

	string RewritePath(HttpRequest request) {
		if(!request.session) {
			return "/login";
		}
		return request.path;
	}
}
