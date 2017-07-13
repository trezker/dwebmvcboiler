module application.UserCreator;

import mondo;
import bsond;
import std.json;
import vibe.http.server;
import application.storage.user;
import boiler.HttpHandlerTester;
import boiler.Ajax;

class UserCreator: RequestHandler {
	User_storage user_storage;

	void setup(User_storage user_storage) {
		user_storage = user_storage;
	}	

	void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
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
			if(obj == BO()) {
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
		catch(Exception) {
			//Write result
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
		}
	}

	//Create user without parameters should fail.
	unittest {
		UserCreator m = new UserCreator;
		auto mongo = new Mongo("mongodb://localhost");
		m.setup(new User_storage(mongo.boiler.user));

		HTTPHandlerTester tester = new HTTPHandlerTester(&m.handleRequest);

		JSONValue json = tester.get_response_json();
		assert(json["success"] == JSONValue(false));
	}
}