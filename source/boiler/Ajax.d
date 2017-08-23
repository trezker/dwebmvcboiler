module boiler.Ajax;

import std.json;
import std.stdio;
import vibe.http.server;

import boiler.ActionTester;
import boiler.model;
import boiler.HttpRequest;
import boiler.HttpResponse;

class Ajax: Action {
	private Action[string] actions;

	public void SetAction(string name, Action action) {
		actions[name] = action;
	}

	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res;
		try {
			string action = req.json["action"].str;
			if(action in actions) {
				res = actions[action].Perform (req);
			}
			else {
				res = new HttpResponse;
				JSONValue json;
				json["success"] = false;
				res.writeBody(json.toString, 200);
			}
		}
		catch(Exception e) {
			res = new HttpResponse;
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
		}
		return res;
	}
}

class SuccessTestHandler : Action {
	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		JSONValue json;
		json["success"] = true;
		res.writeBody(json.toString, 200);
		return res;
	}
}

//Call without parameters should fail.
unittest {
	Ajax ajax = new Ajax();

	ActionTester tester = new ActionTester(&ajax.Perform);

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(false));
}

//Call to method that doesn't exist should fail.
unittest {
	Ajax ajax = new Ajax();

	ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"none\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(false));
}

//Call to method that exists should succeed.
unittest {
	Ajax ajax = new Ajax();
	ajax.SetAction("test", new SuccessTestHandler);

	ActionTester tester = new ActionTester(&ajax.Perform, "{\"action\": \"test\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(true));
}
