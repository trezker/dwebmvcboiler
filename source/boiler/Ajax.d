module boiler.Ajax;

import std.json;
import std.stdio;
import vibe.http.server;

import boiler.ActionTester;
import boiler.HttpRequest;
import boiler.HttpResponse;

alias ActionCreator = Action delegate();

class Ajax: Action {
	private ActionCreator[string] actionCreators;

	public void SetActionCreator(string name, ActionCreator actionCreator) {
		actionCreators[name] = actionCreator;
	}

	public HttpResponse Perform(HttpRequest req) {
		HttpResponse res;
		try {
			string actionName = req.json["action"].str;
			if(actionName in actionCreators) {
				Action action = actionCreators[actionName]();
				res = action.Perform (req);
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
