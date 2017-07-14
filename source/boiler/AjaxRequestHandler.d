module boiler.Ajax;

import boiler.HttpHandlerTester;
import boiler.model;
import vibe.http.server;
import std.json;

interface RequestHandler {
	public void HandleRequest(HTTPServerRequest req, HTTPServerResponse res);
}

class AjaxRequestHandler {
	private RequestHandler[string] handlers;

	public void SetHandler(string name, RequestHandler handler) {
		handlers[name] = handler;
	}

	public void HandleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		try {
			string method = req.json["method"].to!string;
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

	//Call without parameters should fail.
	unittest {
		AjaxRequestHandler handler = new AjaxRequestHandler();

		HTTPHandlerTester tester = new HTTPHandlerTester(&handler.HandleRequest);

		JSONValue json = tester.get_response_json();
		assert(json["success"] == JSONValue(false));
	}

	//Call to method that doesn't exist should fail.
	unittest {
		AjaxRequestHandler handler = new AjaxRequestHandler();

		HTTPHandlerTester tester = new HTTPHandlerTester(&handler.HandleRequest, "{\"method\": \"none\"}");

		JSONValue json = tester.get_response_json();
		assert(json["success"] == JSONValue(false));
	}

	//Call to method that exists should succeed.
	unittest {
		AjaxRequestHandler handler = new AjaxRequestHandler();
		handler.SetHandler("test", new SuccessTestHandler);

		HTTPHandlerTester tester = new HTTPHandlerTester(&handler.HandleRequest, "{\"method\": \"test\"}");

		JSONValue json = tester.get_response_json();
		assert(json["success"] == JSONValue(true));
	}
}

class SuccessTestHandler : RequestHandler {
	public void HandleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		JSONValue json;
		json["success"] = true;
		res.writeBody(json.toString, 200);
		return;
	}
}
