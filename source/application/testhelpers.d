module application.testhelpers;

import application.UserCreator;
import application.database;
import application.storage.user;
import boiler.ActionTester;
import std.json;

void CreateTestUser(string name, string password) {
	Database database = GetDatabase();
	
	UserCreator m = new UserCreator;
	m.setup(new User_storage(database));
	JSONValue jsoninput;
	jsoninput["username"] = name;
	jsoninput["password"] = password;

	ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

	database.Sync();
}