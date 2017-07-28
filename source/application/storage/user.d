module application.storage.user;

import std.json;
import std.conv;
import std.stdio;
import std.algorithm;
import std.exception;
import dauth;
import vibe.db.mongo.mongo;
import vibe.data.bson;

import boiler.helpers;
import application.database;

class User_storage {
	MongoCollection collection;
	this(MongoCollection c) {
		collection = c;
	}

	void create_user(string username, string password) {
		try {
			collection.insert(
				Bson([
					"username": Bson(username),
					"password": Bson(password)
				])
			);
		}
		catch(Exception e) {
			//if(!canFind(e.msg, "duplicate key error")) {
				//log unexpected exception
			//}
			throw e;
		}
	}

	/// create user
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database.GetCollection("my_collection"));
			assertNotThrown(us.create_user("name", "pass"));
		}
		finally {
			database.ClearCollection("my_collection");
		}
	}

	/// unique username
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database.GetCollection("my_collection"));
			
			assertNotThrown(us.create_user("name", "pass"));
			assertNotThrown(us.create_user("name", "pass"));
			
			Bson query = Bson(["username" : Bson("name")]);
			auto result = database.GetCollection("my_collection").find(query);
			JSONValue json = parseJSON(to!string(result));
			assertEqual(1, json.array.length);
		}
		finally {
			database.ClearCollection("my_collection");
		}
	}

	Bson get_user_by_name(string username) {
		auto condition = Bson(["username": Bson(username)]);
		auto obj = collection.findOne(condition);
		return obj;
	}

	/// find user
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database.GetCollection("my_collection"));
			auto username = "name"; 
			us.create_user("wrong", "");
			us.create_user(username, "");
			auto obj = us.get_user_by_name(username);

			assertEqual(obj["username"].get!string, username);
		}
		finally {
			database.ClearCollection("my_collection");
		}
	}

	/// user not found
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database.GetCollection("my_collection"));
			auto username = "name"; 
			auto obj = us.get_user_by_name(username);
			assertEqual(obj, Bson(null));
		}
		finally {
			database.ClearCollection("my_collection");
		}
	}

	Bson find_user_id(BsonObjectID id) {
		auto conditions = Bson(["_id": Bson(id)]);
		auto obj = collection.findOne(conditions);
		return obj;
	}

	/// find user id
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database.GetCollection("my_collection"));
			auto username = "name"; 
			us.create_user("wrong", "");
			us.create_user(username, "");
			auto obj = us.get_user_by_name(username);
			//Testing how to pass around id as string and then using it against mongo.
			BsonObjectID oid = obj["_id"].get!BsonObjectID;
			string sid = oid.toString();
			BsonObjectID nid = BsonObjectID.fromString(sid);
			auto objid = us.find_user_id(nid);

			assertEqual(objid["username"].get!string, username);
		}
		finally {
			database.ClearCollection("my_collection");
		}
	}

	unittest {
		char[] pass = "aljksdn".dup;
		string hashString = makeHash(toPassword(pass)).toString();
		pass = "aljksdn".dup;
		assert(isSameHash(toPassword(pass), parseHash(hashString)));
		pass = "alksdn".dup;
		assert(!isSameHash(toPassword(pass), parseHash(hashString)));
	}
}
