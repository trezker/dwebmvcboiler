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
import application.FindCity;
import application.Cities;

class Application {
	void SetupAjaxMethods(Ajax ajax) {
		Database database = GetDatabase(null);
		auto userStorage = new User_storage(database);

		ajax.SetActionCreator("CreateUser", () => new CreateUser(userStorage));
		ajax.SetActionCreator("Login", () => new Login(userStorage));
		ajax.SetActionCreator("Logout", () => new Logout);
		ajax.SetActionCreator("CurrentUser", () => new CurrentUser(userStorage));

		Cities cities = new Cities;
		cities.Load();
		ajax.SetActionCreator("FindCity", () => new FindCity(cities));
	}

	string RewritePath(HttpRequest request) {
		if(!request.session) {
			return "/login";
		}
		return request.path;
	}
}
