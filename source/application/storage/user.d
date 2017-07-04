module application.storage.user;

import mondo;
import bsond;
import dauth;
import std.algorithm;
import std.exception;
import boiler.helpers;


class User_storage {
	Collection collection;
	this(Collection c) {
		collection = c;
	}

	void create_user(string username, string password) {
		try {
			collection.insert(
				BO(
					"username", username,
					"password", password
				)
			);
		}
		catch(Exception e) {
			if(!canFind(e.msg, "duplicate key error")) {
				//log unexpected exception
			}
			throw e;
		}
	}

	/// create user
	unittest {
		Mongo mongo = new Mongo("mongodb://localhost");
		auto collection = mongo.my_database.my_collection;

		try {
			User_storage us = new User_storage(collection);
			assertNotThrown(us.create_user("name", "pass"));
		}
		finally {
			collection.remove(BO());
		}
		
	}

	/// unique username
	unittest {
		Mongo mongo = new Mongo("mongodb://localhost");
		auto collection = mongo.my_database.my_collection;

		try {
			User_storage us = new User_storage(collection);
			assertNotThrown(us.create_user("name", "pass"));
			assertThrown(us.create_user("name", "pass"));
		}
		finally {
			collection.remove(BO());
		}
	}

	BsonObject find_user(string username) {
		Query q = new Query();
		q.conditions = BO("username", username);
		auto obj = collection.findOne(q);
		return obj;
	}


	/// find user
	unittest {
		Mongo mongo = new Mongo("mongodb://localhost");
		auto collection = mongo.my_database.my_collection;

		try {
			User_storage us = new User_storage(collection);
			auto username = "name"; 
			us.create_user("wrong", "");
			us.create_user(username, "");
			auto obj = us.find_user(username);

			assertEqual(obj["username"].as!string, username);
		}
		finally {
			collection.remove(BO());
		}
	}

	/// user not found
	unittest {
		Mongo mongo = new Mongo("mongodb://localhost");
		auto collection = mongo.my_database.my_collection;

		try {
			User_storage us = new User_storage(collection);
			auto username = "name"; 
			auto obj = us.find_user(username);
			assertEqual(obj, BO());
		}
		finally {
			collection.remove(BO());
		}
	}

	BsonObject find_user_id(ObjectId id) {
		Query q = new Query();
		q.conditions = BO("_id", id);
		auto obj = collection.findOne(q);
		return obj;
	}

	/// find user id
	unittest {
		Mongo mongo = new Mongo("mongodb://localhost");
		auto collection = mongo.my_database.my_collection;

		try {
			User_storage us = new User_storage(collection);
			auto username = "name"; 
			us.create_user("wrong", "");
			us.create_user(username, "");
			auto obj = us.find_user(username);
			//Testing how to pass around id as string and then using it against mongo.
			ObjectId oid = obj["_id"].as!ObjectId;
			string sid = oid.toString().dup[10..34];
			ObjectId nid = sid;
			auto objid = us.find_user_id(nid);

			assertEqual(objid["username"].as!string, username);
		}
		finally {
			collection.remove(BO());
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
