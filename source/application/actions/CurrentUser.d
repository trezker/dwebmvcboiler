module application.CurrentUser;

import std.json;
import std.stdio;
import vibe.http.server;
import vibe.data.bson;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.storage.user;

import std.typecons;

class CurrentUser: Action {
	User_storage user_storage;

	this(User_storage user_storage) {
		this.user_storage = user_storage;
	}	

	HttpResponse Perform(HttpRequest request) {
		HttpResponse response = new HttpResponse;
		try {
			string username = "";
			if(request.session) {
				auto id = request.session.get!string("id");
				auto user = user_storage.UserById(id);
				username = user["username"].get!string;
			}

			JSONValue json;
			json["success"] = true;
			json["username"] = username;
			response.writeBody(json.toString, 200);
		}
		catch(Exception e) {
			JSONValue json;
			json["success"] = false;
			response.writeBody(json.toString, 200);
		}
		return response;
	}
}

//CurrentUser should return the name of logged in user
unittest {
	import application.testhelpers;
	import application.Database;

	Database database = GetDatabase();
	
	try {
		CreateTestUser("testname", "testpass");
		auto tester = TestLogin("testname", "testpass");

		CurrentUser currentUser = new CurrentUser(new User_storage(database));
		tester.Request(&currentUser.Perform);
		
		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(true));
		assert(json["username"] == JSONValue("testname"));
	}
	finally {
		database.ClearCollection("user");
	}
}

//CurrentUser should give no name if not logged in
unittest {
	import application.testhelpers;
	import application.Database;
	import application.Login;

	Database database = GetDatabase();
	
	try {
		CurrentUser currentUser = new CurrentUser(new User_storage(database));
		ActionTester tester = new ActionTester(&currentUser.Perform);
		
		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(true));
		assert(json["username"] == JSONValue(""));
	}
	finally {
		database.ClearCollection("user");
	}
}
