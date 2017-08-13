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
	HTTPServerRequest request;
	HTTPServerResponse response;
	MemoryStream response_stream;
	ubyte[1000000] outputdata;
	SessionStore sessionstore;
	string sessionID;

	this(Request_delegate handler) {
		sessionstore = new MemorySessionStore ();
		Request(handler);
	}

	this(Request_delegate handler, string input) {
		sessionstore = new MemorySessionStore ();
		Request(handler, input);
	}

	public void Request(Request_delegate handler) {
		InetHeaderMap headers;
		if(sessionID != null) {
			headers["Cookie"] = "vibe.session_id=" ~ sessionID;
		}
		request = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST, headers);
		CallHandler(handler);
	}

	public void Request(Request_delegate handler, string input) {
		PrepareJsonRequest(input);
		CallHandler(handler);
	}

	private void PrepareJsonRequest(string input) {
		InetHeaderMap headers;
		headers["Content-Type"] = "application/json";

		if(sessionID != null) {
			headers["Cookie"] = "vibe.session_id=" ~ sessionID;
		}

		auto inputStream = createInputStreamFromString(input);
		request = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST, headers, inputStream);
		PopulateRequestJson();
	}

	private void PopulateRequestJson() {
		// NOTICE: Code lifted from vibe.d source handleRequest
		if (icmp2(request.contentType, "application/json") == 0 || icmp2(request.contentType, "application/vnd.api+json") == 0 ) {
			auto bodyStr = () @trusted { return cast(string)request.bodyReader.readAll(); } ();
			if (!bodyStr.empty) request.json = parseJson(bodyStr);
		}
	}

	private void CallHandler(Request_delegate handler) {
		for(int i = 0; outputdata[i] != 0; ++i) {
			outputdata[i] = 0;
		}
		response_stream = new MemoryStream(outputdata);
		response = createTestHTTPServerResponse(response_stream, sessionstore);
		SetSessionFromCookie();
		handler(request, response);
		sessionID = GetResponseSessionID();
	}

	private void SetSessionFromCookie() {
		// NOTICE: Code lifted from vibe.d source handleRequest
		// use the first cookie that contains a valid session ID in case
		// of multiple matching session cookies
		auto pv = "cookie" in request.headers;
		if (pv) parseCookies(*pv, request.cookies);
		foreach (val; request.cookies.getAll("vibe.session_id")) {
			request.session = sessionstore.open(val);
			//response.m_session = request.session;
			if (request.session) break;
		}
	}
	
	// NOTICE: Code lifted from vibe.d source handleRequest
	private void parseCookies(string str, ref CookieValueMap cookies)
	@safe {
		import std.encoding : sanitize;
		import std.array : split;
		import std.string : strip;
		import std.algorithm.iteration : map, filter, each;
		import vibe.http.common : Cookie;
		() @trusted { 
			() @trusted { return str.sanitize; } ()
				.split(";")
				.map!(kv => kv.strip.split("="))
				.filter!(kv => kv.length == 2) //ignore illegal cookies
				.each!(kv => cookies.add(kv[0], kv[1], Cookie.Encoding.raw) );
		} ();
	}

	public JSONValue GetResponseJson() {
		auto lines = GetResponseLines();
		return parseJSON(lines[$-1]);
	}

	public const(T) GetResponseSessionValue(T)(string key) {
		string sessionID = GetResponseSessionID();
		if(sessionID == null) {
			return T.init;
		}
		Session session = sessionstore.open(sessionID);
		return session.get!T(key);
	}

	public string GetResponseSessionID() {
		auto lines = GetResponseLines();
		bool pred(string x) { return x.indexOf("session_id") != -1; }
		auto session_lines = find!(pred)(lines);
		if(session_lines.length > 0) {
			string sessionCookieLine = session_lines[0];
			return sessionCookieLine[(indexOf(sessionCookieLine, "=")+1)..indexOf(sessionCookieLine, ";")];
		}
		else {
			return null;
		}
	}

	public string[] GetResponseLines() {
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

	void handleRequest(HTTPServerRequest request, HTTPServerResponse response) {
		called = true;
	}
}

class JsonInputDummyHandler {
	bool receivedJson;
	
	this() {
		receivedJson = false;
	}

	void handleRequest(HTTPServerRequest request, HTTPServerResponse response) {
		if(request.json["data"].to!int == 4) {
			receivedJson = true;
		}
	}
}

class SessionDummyHandler {
	void handleRequest(HTTPServerRequest request, HTTPServerResponse response) {
		auto session = response.startSession();
		session.set("testkey", "testvalue");
		response.writeBody("body", 200);
	}
}

class RequestSessionDummyHandler {
	public bool sessionok;

	this() {
		sessionok = false;
	}

	void handleRequest(HTTPServerRequest request, HTTPServerResponse response) {
		if(request.session) {
			auto id = request.session.get!string("testkey");
			if(id == "testvalue") {
				sessionok = true;
			}
		}
		response.writeBody("body", 200);
	}
}

//Creating a tester with handler calls the handler.
unittest {
	auto dummy = new CallFlagDummyHandler();
	
	auto tester = new HTTPHandlerTester(&dummy.handleRequest);

	assert(dummy.called);
}

//Creating a tester with json post data should give the handler access to the data.
unittest {
	auto dummy = new JsonInputDummyHandler();
	
	auto tester = new HTTPHandlerTester(&dummy.handleRequest, "{ \"data\": 4 }");

	assert(dummy.receivedJson);
}

//When testing a handler that sets session values you should be able to read them
unittest {
	auto dummy = new SessionDummyHandler();
	
	auto tester = new HTTPHandlerTester(&dummy.handleRequest);

	assertNotEqual(tester.GetResponseSessionID(), null);
	string value = tester.GetResponseSessionValue!string("testkey");
	assertEqual(value, "testvalue");
}

//Subsequent calls after session value is set should have that session in request
unittest {
	auto responsesessinohandler = new SessionDummyHandler();
	auto tester = new HTTPHandlerTester(&responsesessinohandler.handleRequest);

	auto requestsessionhandler = new RequestSessionDummyHandler();
	tester.Request(&requestsessionhandler.handleRequest);
		writeln(tester.GetResponseLines());
/*
	requestsessionhandler = new RequestSessionDummyHandler();
	tester.Request(&requestsessionhandler.handleRequest);
*/
	assert(requestsessionhandler.sessionok);
}
