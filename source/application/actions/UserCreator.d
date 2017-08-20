module application.UserCreator;

import std.json;
import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.HttpHandlerTester;
import application.storage.user;
import application.database;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;

class UserCreator: Action {
	User_storage user_storage;

	void setup(User_storage user_storage) {
		this.user_storage = user_storage;
	}	

	void Perform(HttpRequest req, HttpResponse res) {
		//Total remake.
		//Each request handler should be an object by itself.
		//There should be a factory to provide a handler for each request.
		//Keep pools of handlers to reduce allocations?

		//I think I'm best off assuming all parameters are in place, which they should be if this is called from client code.
		//Exceptions should only happen during development or if someone is trying to hack the API.

		try {
			//Read parameters
			string username = req.json["username"].str;
			string password = req.json["password"].str;

			//Check that username is not taken
			auto obj = user_storage.get_user_by_name(username);
			if(obj != Bson(null)) {
				JSONValue json;
				json["success"] = false;
				json["info"] = "Username is taken";
				res.writeBody(json.toString, 200);
				return;
			}

			string hashedPassword = makeHash(toPassword(password.dup)).toString();
			user_storage.create_user(username, hashedPassword);

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
}

//Create user without parameters should fail.
unittest {
	Database database = GetDatabase();
	
	try {
		UserCreator m = new UserCreator;
		m.setup(new User_storage(database));

		HTTPHandlerTester tester = new HTTPHandlerTester(&m.Perform);

		JSONValue json = tester.GetResponseJson();
		assert(json["success"] == JSONValue(false));
	}
	finally {
		database.ClearCollection("user");
	}
}

//Create user with name and password should succeed
unittest {
	Database database = GetDatabase();
	
	try {
		UserCreator m = new UserCreator;
		m.setup(new User_storage(database));
		JSONValue jsoninput;
		jsoninput["username"] = "testname";
		jsoninput["password"] = "testpass";

		HTTPHandlerTester tester = new HTTPHandlerTester(&m.Perform, jsoninput.toString);

		JSONValue jsonoutput = tester.GetResponseJson();
		assert(jsonoutput["success"] == JSONValue(true));
	}
	finally {
		database.ClearCollection("user");
	}
}

//Created user should have a hashed password
unittest {
	Database database = GetDatabase();
	
	try {
		string username = "testname";
		string password = "testpass";

		UserCreator m = new UserCreator;
		auto user_storage = new User_storage(database);
		m.setup(user_storage);
		JSONValue jsoninput;
		jsoninput["username"] = username;
		jsoninput["password"] = password;

		HTTPHandlerTester tester = new HTTPHandlerTester(&m.Perform, jsoninput.toString);
		
		auto obj = user_storage.get_user_by_name(username);
		assert(isSameHash(toPassword(password.dup), parseHash(obj["password"].get!string)));
	}
	finally {
		database.ClearCollection("user");
	}
}
