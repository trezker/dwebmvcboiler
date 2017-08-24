module application.CreateUser;

import std.json;
import std.stdio;
import dauth;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.storage.user;
import application.database;

class CreateUser: Action {
	User_storage user_storage;

	this(User_storage user_storage) {
		this.user_storage = user_storage;
	}

	HttpResponse Perform(HttpRequest req) {
		//Total remake.
		//Each request handler should be an object by itself.
		//There should be a factory to provide a handler for each request.
		//Keep pools of handlers to reduce allocations?

		//I think I'm best off assuming all parameters are in place, which they should be if this is called from client code.
		//Exceptions should only happen during development or if someone is trying to hack the API.
		HttpResponse res = new HttpResponse;
		try {
			//Read parameters
			string username = req.json["username"].str;
			string password = req.json["password"].str;

			//Check that username is not taken
			auto obj = user_storage.UserByName(username);
			if(obj != Bson(null)) {
				JSONValue json;
				json["success"] = false;
				json["info"] = "Username is taken";
				res.writeBody(json.toString, 200);
				return res;
			}

			string hashedPassword = makeHash(toPassword(password.dup)).toString();
			user_storage.Create(username, hashedPassword);

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
		return res;
	}
}

//Create user without parameters should fail.
unittest {
	Database database = GetDatabase();
	
	try {
		CreateUser m = new CreateUser(new User_storage(database));

		ActionTester tester = new ActionTester(&m.Perform);

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
		CreateUser m = new CreateUser(new User_storage(database));
		JSONValue jsoninput;
		jsoninput["username"] = "testname";
		jsoninput["password"] = "testpass";

		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

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

		auto user_storage = new User_storage(database);
		CreateUser m = new CreateUser(user_storage);
		JSONValue jsoninput;
		jsoninput["username"] = username;
		jsoninput["password"] = password;

		ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);
		
		auto obj = user_storage.UserByName(username);
		assert(isSameHash(toPassword(password.dup), parseHash(obj["password"].get!string)));
	}
	finally {
		database.ClearCollection("user");
	}
}
