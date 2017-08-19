module application.Logout;

import std.json;
import std.stdio;
import vibe.http.server;

import boiler.HttpHandlerTester;
import boiler.Ajax;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;

class Logout: RequestHandler {
	void HandleRequest(HttpRequest req, HttpResponse res) {
		try {
			req.TerminateSession();

			JSONValue json;
			json["success"] = true;
			res.writeBody(json.toString, 200);
		}
		catch(Exception e) {
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
		}
	}
}

//Logout should succeed and session should not contain a user id
unittest {
	import application.testhelpers;
	import application.database;
	import application.Login;
	import application.storage.user;

	Database database = GetDatabase();
	
	try {
		CreateTestUser("testname", "testpass");

		Login loginHandler = new Login;
		loginHandler.setup(new User_storage(database));
		JSONValue jsoninput;
		jsoninput["username"] = "testname";
		jsoninput["password"] = "testpass";

		HTTPHandlerTester tester = new HTTPHandlerTester(&loginHandler.HandleRequest, jsoninput.toString);

		Logout logoutHandler = new Logout();
		tester.Request(&logoutHandler.HandleRequest);
		
		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(true));
		string id = tester.GetResponseSessionValue!string("id");
		assertEqual(id, "");
	}
	finally {
		database.ClearCollection("user");
	}
}
