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
import std.stdio;
import std.algorithm;

class HTTPHandlerTester {
	HTTPServerRequest req;
	HTTPServerResponse res;
	MemoryStream response_stream;
	ubyte[1000000] outputdata;
	SessionStore sessionstore;

	this(Request_delegate handler) {
		req = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST);//, InetHeaderMap headers, InputStream data = null)
		sessionstore = new MemorySessionStore ();
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
		sessionstore = new MemorySessionStore ();
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
		res = createTestHTTPServerResponse(response_stream, sessionstore);
		handler(req, res);
		//res.finalize;
	}

	public JSONValue get_response_json() {
		auto lines = getResponseLines();
		return parseJSON(lines[$-1]);
	}

	public const(T) GetResponseSessionValue(T)(string key) {
		string sessionID = GetResponseSessionID();
		Session session = sessionstore.open(sessionID);
		return session.get!T(key);
	}

	public string GetResponseSessionID() {
		auto lines = getResponseLines();
		bool pred(string x) { return x.indexOf("session_id") != -1; }
		auto session_lines = find!(pred)(lines);
		if(session_lines.length > 0) {
			string sessionCookieLine = session_lines[0];
			return sessionCookieLine[(indexOf(sessionCookieLine, "=")+1)..indexOf(sessionCookieLine, ";")];
		}
		else {
			return "";
		}
	}

	//When testing a handler that sets session values you should be able to read them
	unittest {
		auto dummy = new SessionDummyHandler();
		
		auto tester = new HTTPHandlerTester(&dummy.handleRequest);

		assertNotEqual(tester.GetResponseSessionID(), "");
		string value = tester.GetResponseSessionValue!string("testkey");
		assertEqual(value, "testvalue");
	}

	public string[] getResponseLines() {
		response_stream.seek(0);
 		string rawResponse = response_stream.readAllUTF8();
 		rawResponse = rawResponse[0..indexOf(rawResponse, "\0")];
		return rawResponse.splitLines();
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
		if(req.json["data"].to!int == 4) {
			receivedJson = true;
		}
	}
}

class SessionDummyHandler {
	void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
		auto session = res.startSession();
		session.set("testkey", "testvalue");
		res.writeBody("body", 200);
	}
}