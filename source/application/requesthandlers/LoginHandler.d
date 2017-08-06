module application.LoginHandler;

import std.json;
import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.HttpHandlerTester;
import boiler.Ajax;
import application.storage.user;
import application.database;

class LoginHandler: RequestHandler {
	User_storage user_storage;

	void setup(User_storage user_storage) {
		this.user_storage = user_storage;
	}	

	void HandleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		try {
			//Read parameters
			string username = req.json["username"].to!string;
			string password = req.json["password"].to!string;

			//Get user
			auto obj = user_storage.get_user_by_name(username);
			if(obj == Bson(null)) {
				JSONValue json;
				json["success"] = false;
				json["info"] = "Invalid login";
				res.writeBody(json.toString, 200);
				return;
			}

			//Verify password
			if(!isSameHash(toPassword(password.dup), parseHash(obj["password"].get!string))) {
				JSONValue json;
				json["success"] = false;
				json["info"] = "Invalid login password";
				res.writeBody(json.toString, 200);
				return;
			}

			//Initiate session

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

		}
	}

	//Login user without parameters should fail
	unittest {
		Database database = GetDatabase();
		
		try {
			LoginHandler m = new LoginHandler;
			m.setup(new User_storage(database));

			HTTPHandlerTester tester = new HTTPHandlerTester(&m.HandleRequest);

			JSONValue json = tester.get_response_json();
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
			LoginHandler m = new LoginHandler;
			m.setup(new User_storage(database));
			JSONValue jsoninput;
			jsoninput["username"] = "testname";
			jsoninput["password"] = "testpass";

			HTTPHandlerTester tester = new HTTPHandlerTester(&m.HandleRequest, jsoninput.toString);

			JSONValue json = tester.get_response_json();
			assert(json["success"] == JSONValue(false));
		}
		finally {
			database.ClearCollection("user");
		}
	}

	//Login user with correct parameters should succeed
	unittest {
		import application.testhelpers;

		Database database = GetDatabase();
		
		try {
			CreateTestUser("testname", "testpass");

			LoginHandler m = new LoginHandler;
			m.setup(new User_storage(database));
			JSONValue jsoninput;
			jsoninput["username"] = "testname";
			jsoninput["password"] = "testpass";

			HTTPHandlerTester tester = new HTTPHandlerTester(&m.HandleRequest, jsoninput.toString);

			JSONValue json = tester.get_response_json();
			assert(json["success"] == JSONValue(true));
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

			LoginHandler m = new LoginHandler;
			m.setup(new User_storage(database));
			JSONValue jsoninput;
			jsoninput["username"] = "testname";
			jsoninput["password"] = "wrong";

			HTTPHandlerTester tester = new HTTPHandlerTester(&m.HandleRequest, jsoninput.toString);

			JSONValue json = tester.get_response_json();
			assert(json["success"] == JSONValue(false));
		}
		finally {
			database.ClearCollection("user");
		}
	}
}