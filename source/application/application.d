module application.application;

import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.Ajax;
import boiler.HttpRequest;

import application.Database;
import application.storage.user;
import application.CreateUser;
import application.Login;
import application.Logout;
import application.CurrentUser;

class Application {
	void SetupAjaxMethods(Ajax ajax) {
		Database database = GetDatabase(null);
		auto userStorage = new User_storage(database);

		auto createUser = new CreateUser(userStorage);
		ajax.SetAction("CreateUser", createUser);

		auto login = new Login(userStorage);
		ajax.SetAction("Login", login);

		ajax.SetAction("Logout", new Logout);

		auto currentUser = new CurrentUser(userStorage);
		ajax.SetAction("CurrentUser", currentUser);
	}

	string RewritePath(HttpRequest request) {
		if(!request.session) {
			return "/login";
		}
		return request.path;
	}
}
