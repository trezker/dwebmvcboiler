module boiler.HttpHandlerTester;

import boiler.model;
import boiler.helpers;
import vibe.inet.url;
import vibe.data.json;
import vibe.http.server;
import vibe.utils.string;
import vibe.inet.message;
import vibe.stream.memory;
import vibe.stream.operations;
import std.json;

class HTTPHandlerTester {
	HTTPServerRequest req;
	HTTPServerResponse res;
	MemoryStream response_stream;
	ubyte[1000000] outputdata;

	this(Request_delegate handler) {
		req = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST);//, InetHeaderMap headers, InputStream data = null)
		call_handler(handler);
	}

	//Creating a tester with handler calls the handler.
	unittest {
		auto dummy = new CallFlagDummyHandler();
		
		auto tester = new HTTPHandlerTester(&dummy.handleRequest);

		assert(dummy.called);
	}

	this(Request_delegate handler, string input) {
		PrepareJsonRequest(input);
		call_handler(handler);
	}

	//Creating a tester with json post data should give the handler access to the data.
	unittest {
		auto dummy = new JsonInputDummyHandler();
		
		auto tester = new HTTPHandlerTester(&dummy.handleRequest, "{ \"data\": 4 }");

		assert(dummy.receivedJson);
	}

	private void PrepareJsonRequest(string input) {
		InetHeaderMap headers;
		headers["Content-Type"] = "application/json";

		auto inputStream = createInputStreamFromString(input);
		req = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST, headers, inputStream);
		populateRequestJson();
	}

	private void populateRequestJson() {
		if (icmp2(req.contentType, "application/json") == 0 || icmp2(req.contentType, "application/vnd.api+json") == 0 ) {
			auto bodyStr = () @trusted { return cast(string)req.bodyReader.readAll(); } ();
			if (!bodyStr.empty) req.json = parseJson(bodyStr);
		}
	}

	private void call_handler(Request_delegate handler) {
		response_stream = new MemoryStream(outputdata);
		res = createTestHTTPServerResponse(response_stream);//SessionStore session_store = null)
		handler(req, res);
		res.finalize;
	}

	public string[] getResponseLines() {
		response_stream.seek(0);
 		string rawResponse = response_stream.readAllUTF8();
		return rawResponse.splitLines();
	}

	public JSONValue get_response_json() {
		auto lines = getResponseLines();
		return parseJSON(lines[$-1]);
	}

	//TODO: Test get_response_json
}

class CallFlagDummyHandler {
	bool called;
	
	this() {
		called = false;
	}

	void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		called = true;
	}
}

class JsonInputDummyHandler {
	bool receivedJson;
	
	this() {
		receivedJson = false;
	}

	void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		if(req.json["data"].to!int == 4) {
			receivedJson = true;
		}
	}
}