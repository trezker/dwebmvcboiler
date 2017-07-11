module boiler.HttpHandlerTester;

import boiler.model;
import vibe.inet.url;
import vibe.data.json;
import vibe.http.server;
import vibe.utils.string;
import vibe.inet.message;
import vibe.stream.memory;
import vibe.stream.operations;
import std.conv;
import std.json;
import std.stdio;
import std.string;


class HTTPHandlerTester {
	HTTPServerRequest req;
	HTTPServerResponse res;
	string rawResponse;
	string[] lines;
	MemoryStream response_stream;
	ubyte[1000000] data;
	ubyte[1000000] inputdata;

	this(Request_delegate handler) {
		req = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST);//, InetHeaderMap headers, InputStream data = null)
		call_handler(handler);
		read_response();
	}

	//Creating a tester with handler calls the handler.
	unittest {
		auto dummy = new CallFlagDummyHandler();
		
		auto tester = new HTTPHandlerTester(&dummy.handleRequest);

		assert(dummy.called);
	}

	private void call_handler(Request_delegate handler) {
		response_stream = new MemoryStream(data);
		res = createTestHTTPServerResponse(response_stream);//SessionStore session_store = null)
		handler(req, res);
		res.finalize;
	}


	this(Request_delegate handler, string input) {
		InetHeaderMap headers;
		headers["Content-Type"] = "application/json";

		auto inputStream = new MemoryStream(inputdata);
		inputStream.write(cast(const(ubyte)[])input);
		inputStream.seek(0);
		req = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST, headers, inputStream);

		if (icmp2(req.contentType, "application/json") == 0 || icmp2(req.contentType, "application/vnd.api+json") == 0 ) {
			auto bodyStr = () @trusted { return cast(string)req.bodyReader.readAll(); } ();
			if (!bodyStr.empty) req.json = parseJson(bodyStr);
		}

		call_handler(handler);
		read_response();
	}

	//Creating a tester with json post data should give the handler access to the data.
	unittest {
		auto dummy = new JsonInputDummyHandler();
		
		auto tester = new HTTPHandlerTester(&dummy.handleRequest, "{ \"data\": 4 }");

		assert(dummy.receivedJson);
	}

	private void read_response() {
		response_stream.seek(0);
 		rawResponse = response_stream.readAllUTF8();
 		lines = rawResponse.splitLines();
	}

	public JSONValue get_response_json() {
		return parseJSON(lines[$-1]);
	}

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
		//writeln(req.contentType);
		//writeln(req.headers);
		//req.bodyReader.seek(0);
 		//writeln(req.bodyReader.readAllUTF8());
		if(req.json["data"].to!int == 4) {
			receivedJson = true;
		}
	}
}