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

	bool json_is_type(Json j, JSON_TYPE t) {
		if (j.type() == t) {
			return true;
		}
		else {
			return false;
		}
	}

	void create_user(HTTPServerRequest req, HTTPServerResponse res) {
		if(!json_is_type(req.json, JSON_TYPE.OBJECT)) {
			JSONValue json;
			json["success"] = false;
			json["info"] = "Missing parameters";
			res.writeBody(json.toString, 200);
			return;
		}

		if(!json_is_type(req.json["username"], JSON_TYPE.STRING)) {
			JSONValue json;
			json["success"] = false;
			json["info"] = "Missing parameter: username";
			res.writeBody(json.toString, 200);
			return;
		}

		if(req.json["password"] == JSON_TYPE.NULL){
			JSONValue json;
			json["success"] = false;
			json["info"] = "Missing parameter: password";
			res.writeBody(json.toString, 200);
			return;
		}

		string username = req.json["username"].to!string;
		string password = req.json["password"].to!string;

		auto obj = user_storage.get_user_by_name(username);
		if(obj == BO()) {
			JSONValue json;
			json["success"] = false;
			json["info"] = "Username is taken";
			res.writeBody(json.toString, 200);
			return;
		}

		try {
			user_storage.create_user(username, password);

			JSONValue json;
			json["success"] = true;
			res.writeBody(json.toString, 200);
		}
		catch(Exception) {
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
