module application.application;

import vibe.http.server;
import vibe.core.log;

import mondo;
import boiler.model;
import boiler.Ajax;
import boiler.HttpRequest;

import application.database;
import application.storage.user;
import application.CreateUser;
import application.Login;
import application.Logout;
import application.CurrentUser;

class Application {
	void SetupAjaxMethods(Ajax ajax) {
		Database database = GetDatabase();
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
