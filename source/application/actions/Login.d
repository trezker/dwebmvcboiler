module application.Login;

import std.json;
import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.HttpRequest;
import boiler.HttpResponse;
import boiler.ActionTester;
import boiler.helpers;
import application.storage.user;
import application.database;
import application.testhelpers;

class Login: Action {
	User_storage user_storage;

	void setup(User_storage user_storage) {
		this.user_storage = user_storage;
	}	

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			//Read parameters
			string username = req.json["username"].str;
			string password = req.json["password"].str;

			//Get user
			auto obj = user_storage.UserByName(username);
			if(obj == Bson(null)) {
				JSONValue json;
				json["success"] = false;
				json["info"] = "Invalid login";
				res.writeBody(json.toString, 200);
				return res;
			}

			//Verify password
			if(!isSameHash(toPassword(password.dup), parseHash(obj["password"].get!string))) {
				JSONValue json;
				json["success"] = false;
				json["info"] = "Invalid login password";
				res.writeBody(json.toString, 200);
				return res;
			}

			//Initiate session
			auto session = req.StartSession();
			BsonObjectID oid = obj["_id"].get!BsonObjectID;
			string userID = oid.toString();
			session.set("id", userID);

			//Write result
			JSONValue json;
			json["success"] = true;
			res.writeBody(json.toString, 200);
		}
		catch(Exception e) {
			//Write result
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
			//writeln(e);
		}
		return res;
	}
}

//Login user without parameters should fail
unittest {
	Database database = GetDatabase();
	
	try {
		Login m = new Login;
		m.setup(new User_storage(database));

		ActionTester tester = new ActionTester(&m.Perform);

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(false));
	}
	finally {
		database.ClearCollection("user");
	}
}

//Login user that doesn't exist should fail
unittest {
	Database database = GetDatabase();
	
	try {
		auto tester = TestLogin("testname", "testpass");

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(false));
	}
	finally {
		database.ClearCollection("user");
	}
}

//Login user with correct parameters should succeed and set user id in session
unittest {
	import application.testhelpers;

	Database database = GetDatabase();
	
	try {
		CreateTestUser("testname", "testpass");

		Login m = new Login;
		m.setup(new User_storage(database));
		JSONValue jsoninput;
		jsoninput["username"] = "testname";
		jsoninput["password"] = "testpass";

		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(true));
		string id = tester.GetResponseSessionValue!string("id");
		assertNotEqual(id, "");
	}
	finally {
		database.ClearCollection("user");
	}
}

//Login user with incorrect password should fail
unittest {
	import application.testhelpers;

	Database database = GetDatabase();
	
	try {
		CreateTestUser("testname", "testpass");

		auto tester = TestLogin("testname", "wrong");

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(false));
	}
	finally {
		database.ClearCollection("user");
	}
}
