module application.UserCreator;

import std.json;
import std.stdio;
import vibe.http.server;
import vibe.db.mongo.mongo;

import boiler.HttpHandlerTester;
import boiler.Ajax;
import application.storage.user;

class UserCreator: RequestHandler {
	User_storage user_storage;

	void setup(User_storage user_storage) {
		this.user_storage = user_storage;
	}	

	void HandleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		//Total remake.
		//Each request handler should be an object by itself.
		//There should be a factory to provide a handler for each request.
		//Keep pools of handlers to reduce allocations?

		//I think I'm best off assuming all parameters are in place, which they should be if this is called from client code.
		//Exceptions should only happen during development or if someone is trying to hack the API.

		try {
			//Read parameters
			string username = req.json["username"].to!string;
			string password = req.json["password"].to!string;

			//Check that username is not taken
			auto obj = user_storage.get_user_by_name(username);
			if(obj != Bson(null)) {
				JSONValue json;
				json["success"] = false;
				json["info"] = "Username is taken";
				res.writeBody(json.toString, 200);
				return;
			}

			user_storage.create_user(username, password);

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
/*
	//Create user without parameters should fail.
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");
		
		try {
			UserCreator m = new UserCreator;
			m.setup(new User_storage(collection));

			HTTPHandlerTester tester = new HTTPHandlerTester(&m.HandleRequest);

			JSONValue json = tester.get_response_json();
			assert(json["success"] == JSONValue(false));
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}
*/
	//Create user with name and password should succeed
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");
		
		try {
			UserCreator m = new UserCreator;
			m.setup(new User_storage(collection));
			JSONValue jsoninput;
			jsoninput["username"] = "testname";
			jsoninput["password"] = "testpass";

			HTTPHandlerTester tester = new HTTPHandlerTester(&m.HandleRequest, jsoninput.toString);

			JSONValue jsonoutput = tester.get_response_json();
			writeln(jsonoutput);
			assert(jsonoutput["success"] == JSONValue(true));
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}
}