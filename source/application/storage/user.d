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
	Database database;
	MongoCollection collection;
	this(Database database) {
		this.database = database;
		collection = database.GetCollection("user");
	}

	void Create(string username, string password) {
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
			User_storage us = new User_storage(database);
			assertNotThrown(us.Create("name", "pass"));
		}
		finally {
			database.ClearCollection("user");
		}
	}

	/// unique username
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database);
			
			assertNotThrown(us.Create("name", "pass"));
			assertNotThrown(us.Create("name", "pass"));
			
			Bson query = Bson(["username" : Bson("name")]);
			auto result = database.GetCollection("user").find(query);
			JSONValue json = parseJSON(to!string(result));
			assertEqual(1, json.array.length);
		}
		finally {
			database.ClearCollection("user");
		}
	}

	Bson UserByName(string username) {
		auto condition = Bson(["username": Bson(username)]);
		auto obj = collection.findOne(condition);
		return obj;
	}

	/// find user
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database);
			auto username = "name"; 
			us.Create("wrong", "");
			us.Create(username, "");
			auto obj = us.UserByName(username);

			assertEqual(obj["username"].get!string, username);
		}
		finally {
			database.ClearCollection("user");
		}
	}

	/// user not found
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database);
			auto username = "name"; 
			auto obj = us.UserByName(username);
			assertEqual(obj, Bson(null));
		}
		finally {
			database.ClearCollection("user");
		}
	}

	Bson UserById(string id) {
		BsonObjectID oid = BsonObjectID.fromString(id);
		auto conditions = Bson(["_id": Bson(oid)]);
		auto obj = collection.findOne(conditions);
		return obj;
	}

	/// find user id
	unittest {
		Database database = GetDatabase();

		try {
			User_storage us = new User_storage(database);
			auto username = "name"; 
			us.Create("wrong", "");
			us.Create(username, "");
			auto obj = us.UserByName(username);
			//Testing how to pass around id as string and then using it against mongo.
			BsonObjectID oid = obj["_id"].get!BsonObjectID;
			string sid = oid.toString();
			auto objid = us.UserById(sid);

			assertEqual(objid["username"].get!string, username);
		}
		finally {
			database.ClearCollection("user");
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
