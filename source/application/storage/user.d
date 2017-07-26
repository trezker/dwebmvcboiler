module application.storage.user;

import std.json;
import std.conv;
import std.stdio;
import std.algorithm;
import std.exception;
import dauth;
import boiler.helpers;

import vibe.db.mongo.mongo;
import vibe.data.bson;

class MongoAlloc {
	static:
	private MongoClient pool;
	public MongoClient GetConnection() {
		return connectMongoDB("mongodb://localhost");
		/*
		if(!pool)
			pool = connectMongoDB("mongodb://localhost");
		return pool;
		*/
	}

}

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
/*
	/// create user
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");

		try {
			User_storage us = new User_storage(collection);
			assertNotThrown(us.create_user("name", "pass"));
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}

	/// unique username
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");

		try {
			User_storage us = new User_storage(collection);
			
			assertNotThrown(us.create_user("name", "pass"));
			assertNotThrown(us.create_user("name", "pass"));
			
			Bson query = Bson(["username" : Bson("name")]);
			auto result = collection.find(query);
			JSONValue json = parseJSON(to!string(result));
			assertEqual(1, json.array.length);
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}
*/
	Bson get_user_by_name(string username) {
		auto condition = Bson(["username": Bson(username)]);
		auto obj = collection.findOne(condition);
		return obj;
	}
/*
	/// find user
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");

		try {
			User_storage us = new User_storage(collection);
			auto username = "name"; 
			us.create_user("wrong", "");
			us.create_user(username, "");
			auto obj = us.get_user_by_name(username);

			assertEqual(obj["username"].get!string, username);
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}

	/// clear collection
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");

		try {
			User_storage us = new User_storage(collection);
			auto username = "name"; 
			us.create_user(username, "");
			auto obj = us.get_user_by_name(username);

			assertEqual(obj["username"].get!string, username);

			collection.remove();
			obj = us.get_user_by_name(username);
			assertEqual(obj, Bson(null));
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}

	/// user not found
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");

		try {
			User_storage us = new User_storage(collection);
			auto username = "name"; 
			auto obj = us.get_user_by_name(username);
			assertEqual(obj, Bson(null));
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}
*/
	Bson find_user_id(BsonObjectID id) {
		auto conditions = Bson(["_id": Bson(id)]);
		auto obj = collection.findOne(conditions);
		return obj;
	}
/*
	/// find user id
	unittest {
		MongoClient mongo = MongoAlloc.GetConnection();
		auto collection = mongo.getCollection("my_database.my_collection");

		try {
			User_storage us = new User_storage(collection);
			auto username = "name"; 
			us.create_user("wrong", "");
			us.create_user(username, "");
			auto obj = us.get_user_by_name(username);
			//Testing how to pass around id as string and then using it against mongo.
			BsonObjectID oid = obj["_id"].get!BsonObjectID;
			string sid = oid.toString();//.dup[10..34];
			BsonObjectID nid = BsonObjectID.fromString(sid);
			auto objid = us.find_user_id(nid);

			assertEqual(objid["username"].get!string, username);
		}
		finally {
			collection.remove();
			auto db = mongo.getDatabase("my_database");
			db.fsync();
		}
	}
*/
	unittest {
		char[] pass = "aljksdn".dup;
		string hashString = makeHash(toPassword(pass)).toString();
		writeln(hashString);
		pass = "aljksdn".dup;
		assert(isSameHash(toPassword(pass), parseHash(hashString)));
		pass = "alksdn".dup;
		assert(!isSameHash(toPassword(pass), parseHash(hashString)));
	}
}
