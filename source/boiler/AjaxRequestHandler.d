module boiler.Ajax;

import std.json;
import vibe.http.server;

import boiler.HttpHandlerTester;
import boiler.model;
import boiler.HttpRequest;
import boiler.HttpResponse;

interface RequestHandler {
	public void HandleRequest(HttpRequest req, HttpResponse res);
}

class AjaxRequestHandler {
	private RequestHandler[string] handlers;

	public void SetHandler(string name, RequestHandler handler) {
		handlers[name] = handler;
	}

	public void HandleRequest(HttpRequest req, HttpResponse res) {
		try {
			string method = req.json["method"].str;
			if(method in handlers) {
				handlers[method].HandleRequest (req, res);
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

class SuccessTestHandler : RequestHandler {
	public void HandleRequest(HttpRequest req, HttpResponse res) {
		JSONValue json;
		json["success"] = true;
		res.writeBody(json.toString, 200);
		return;
	}
}

//Call without parameters should fail.
unittest {
	AjaxRequestHandler handler = new AjaxRequestHandler();

	HTTPHandlerTester tester = new HTTPHandlerTester(&handler.HandleRequest);

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(false));
}

//Call to method that doesn't exist should fail.
unittest {
	AjaxRequestHandler handler = new AjaxRequestHandler();

	HTTPHandlerTester tester = new HTTPHandlerTester(&handler.HandleRequest, "{\"method\": \"none\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(false));
}

//Call to method that exists should succeed.
unittest {
	AjaxRequestHandler handler = new AjaxRequestHandler();
	handler.SetHandler("test", new SuccessTestHandler);

	HTTPHandlerTester tester = new HTTPHandlerTester(&handler.HandleRequest, "{\"method\": \"test\"}");

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(true));
}
