module application.Logout;

import std.json;
import std.stdio;
import vibe.http.server;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;

class Logout: Action {
	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
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
		return res;
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

		auto tester = TestLogin("testname", "testpass");

		Logout logoutHandler = new Logout();
		tester.Request(&logoutHandler.Perform);
		
		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(true));
		string id = tester.GetResponseSessionValue!string("id");
		assertEqual(id, "");
	}
	finally {
		database.ClearCollection("user");
	}
}
