module application.database;

import vibe.db.mongo.mongo;

Database GetDatabase() {
	return new Database();
}

class Database {
	MongoClient client;
	string dbname;

	this() {
		client = connectMongoDB("mongodb://localhost");
		dbname = "my_database";
	}

	public MongoClient GetClient() {
		return client;
	}

	public MongoCollection GetCollection(string name) {
		return client.getCollection(dbname ~ "." ~ name);
	}

	public void Sync() {
		auto db = client.getDatabase(dbname);
		db.fsync();
	}

	public void ClearCollection(string name) {
		auto collection = GetCollection(name);
		collection.remove();
		Sync();
	}
}