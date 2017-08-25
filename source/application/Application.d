module application.Application;

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

		ajax.SetAction("CreateUser", new CreateUser(userStorage));

		ajax.SetAction("Login", new Login(userStorage));

		ajax.SetAction("Logout", new Logout);

		ajax.SetAction("CurrentUser", new CurrentUser(userStorage));
	}

	string RewritePath(HttpRequest request) {
		if(!request.session) {
			return "/login";
		}
		return request.path;
	}
}
