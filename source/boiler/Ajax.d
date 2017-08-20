module boiler.Ajax;

import std.json;
import vibe.http.server;

import boiler.ActionTester;
import boiler.model;
import boiler.HttpRequest;
import boiler.HttpResponse;

class Ajax: Action {
	private Action[string] handlers;

	public void SetHandler(string name, Action handler) {
		handlers[name] = handler;
	}

	public void Perform(HttpRequest req, HttpResponse res) {
		try {
			string method = req.json["method"].str;
			if(method in handlers) {
				handlers[method].Perform (req, res);
			}
			else {
				JSONValue json;
				json["success"] = false;
				res.writeBody(json.toString, 200);
			}
		}
		catch(Exception e) {
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
		}
	}
}

class SuccessTestHandler : Action {
	public void Perform(HttpRequest req, HttpResponse res) {
		JSONValue json;
		json["success"] = true;
		res.writeBody(json.toString, 200);
		return;
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

	ActionTester tester = new ActionTester(&ajax.Perform, "{\"method\": \"none\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(false));
}

//Call to method that exists should succeed.
unittest {
	Ajax ajax = new Ajax();
	ajax.SetHandler("test", new SuccessTestHandler);

	ActionTester tester = new ActionTester(&ajax.Perform, "{\"method\": \"test\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(true));
}
