module application.testhelpers;

import std.json;
import boiler.ActionTester;
import application.database;
import application.storage.user;
import application.UserCreator;
import application.Login;

void CreateTestUser(string name, string password) {
	Database database = GetDatabase();
	
	UserCreator m = new UserCreator(new User_storage(database));
	JSONValue jsoninput;
	jsoninput["username"] = name;
	jsoninput["password"] = password;

	ActionTester tester = new ActionTester(&m.Perform, jsoninput.toString);

	database.Sync();
}

ActionTester TestLogin(string name, string password) {
	Database database = GetDatabase();
	Login login = new Login;
	login.setup(new User_storage(database));
	JSONValue jsoninput;
	jsoninput["username"] = name;
	jsoninput["password"] = password;
	ActionTester tester = new ActionTester(&login.Perform, jsoninput.toString);
	return tester;
}