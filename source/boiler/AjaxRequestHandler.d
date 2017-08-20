module boiler.Ajax;

import std.json;
import vibe.http.server;

import boiler.HttpHandlerTester;
import boiler.model;
import boiler.HttpRequest;
import boiler.HttpResponse;

class AjaxRequestHandler: Action {
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
	AjaxRequestHandler handler = new AjaxRequestHandler();

	HTTPHandlerTester tester = new HTTPHandlerTester(&handler.Perform);

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(false));
}

//Call to method that doesn't exist should fail.
unittest {
	AjaxRequestHandler handler = new AjaxRequestHandler();

	HTTPHandlerTester tester = new HTTPHandlerTester(&handler.Perform, "{\"method\": \"none\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(false));
}

//Call to method that exists should succeed.
unittest {
	AjaxRequestHandler handler = new AjaxRequestHandler();
	handler.SetHandler("test", new SuccessTestHandler);

	HTTPHandlerTester tester = new HTTPHandlerTester(&handler.Perform, "{\"method\": \"test\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(true));
}
