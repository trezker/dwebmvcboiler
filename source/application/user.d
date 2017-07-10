module application.user;

import vibe.http.server;
import vibe.core.log;
import vibe.data.json;
import mondo;
import std.digest.sha;
import bsond;
import std.stdio;
import std.json;

import boiler.server;
import boiler.model;
import boiler.helpers;
import boiler.httphandlertester;

import application.storage.user;

class User_model {
	Mongo mongo;
	Collection collection;
	User_storage user_storage;

	void setup(Mongo m, ref Model_method[string][string] models) {
		mongo = m;
		collection = mongo.boiler.user;
		user_storage = new User_storage(collection);

		models["user"]["get_current_user_id"] = Model_method(
			[],
			&this.get_current_user_id
		);
		models["user"]["login_password"] = Model_method(
			[],
			&this.login_password
		);
		models["user"]["logout"] = Model_method(
			[],
			&this.logout
		);
		models["user"]["create_user"] = Model_method(
			[],
			&this.create_user
		);
		models["user"]["delete_user"] = Model_method(
			[],
			&this.delete_user
		);
	}

	void create_user(HTTPServerRequest req, HTTPServerResponse res) {
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
		User_model m = new User_model;
		HTTPHandlerTester tester = new HTTPHandlerTester(&m.create_user);
		JSONValue json = tester.get_reponse_json();
		assert(json["success"] == JSONValue(false));
	}

	void get_current_user_id(HTTPServerRequest req, HTTPServerResponse res) {
		if(!req.session) {
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
			return;
		}
		auto id = req.session.get!string("id");
		res.writeJsonBody(id);
	}

	unittest {
		User_model m = new User_model;
		HTTPHandlerTester tester = new HTTPHandlerTester(&m.get_current_user_id);
		JSONValue json = tester.get_reponse_json();
		assert(json["success"] == JSONValue(false));
	}

	void login_password(HTTPServerRequest req, HTTPServerResponse res) {
		//Do not allow double login, must log out first.
		//But we'll help out by terminating the old session to get a clean state.
		if(req.session) {
			res.terminateSession();
			res.writeJsonBody(false);
			return;
		}

		string username = req.json["username"].to!string;
		string password = req.json["password"].to!string;

		Collection user_collection = mongo.journal.user;

		Query q = new Query();
		q.conditions["name"] = username;
		q.fields["_id"] = true;
		q.fields["pass"] = true;
		q.fields["salt"] = true;
		auto r = user_collection.find(q);
		if(r.empty) {
			res.writeJsonBody(false);
			return;
		}
		auto user = r.front;

		ubyte[32] hash = sha512_256Of(user["salt"].as!string ~ password);
		string hashed_password = toHexString(hash);
		if(user["pass"].as!string != hashed_password) {
			res.writeJsonBody(false);
			return;
		}

		auto session = res.startSession();
		string user_id = user["_id"].as!string;
		session.set("id", user_id);
		res.writeJsonBody(true);
	}

	void logout(HTTPServerRequest req, HTTPServerResponse res) {
		if(req.session) {
			res.terminateSession();
		}
		res.writeJsonBody(true);
	}

	void delete_user(HTTPServerRequest req, HTTPServerResponse res) {
		string username = req.json["username"].to!string;
		//Method only for testing, in real usage users are never deleted.
		if(username != "testuser")
		{
			res.writeJsonBody(true);
			return;
		}

		Collection user_collection = mongo.journal.user;
		user_collection.remove(BO(
				"name", username
			)
		);

		res.writeJsonBody(true);
	}
}
