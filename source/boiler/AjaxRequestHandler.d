module boiler.AjaxRequestHandler;

import boiler.HttpHandlerTester;
import vibe.http.server;
import std.json;

class AjaxRequestHandler {
	void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		JSONValue json;
		json["success"] = false;
		res.writeBody(json.toString, 200);
	}

	//Call without parameters should fail.
	unittest {
		AjaxRequestHandler handler = new AjaxRequestHandler();

		HTTPHandlerTester tester = new HTTPHandlerTester(&handler.handleRequest);

		JSONValue json = tester.get_response_json();
		assert(json["success"] == JSONValue(false));
	}

	//Call to method that doesn't exist should fail.
	unittest {
		AjaxRequestHandler handler = new AjaxRequestHandler();
		//TODO: initiate tester with request data

		HTTPHandlerTester tester = new HTTPHandlerTester(&handler.handleRequest);

		JSONValue json = tester.get_response_json();
		assert(json["success"] == JSONValue(false));
	}
}
