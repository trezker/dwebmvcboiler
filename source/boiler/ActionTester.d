module boiler.ActionTester;

import std.json;
import std.stdio;
import std.algorithm;
import vibe.inet.url;
import vibe.data.json;
import vibe.http.server;
import vibe.utils.string;
import vibe.inet.message;
import vibe.stream.memory;
import vibe.stream.operations;

import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;

alias Request_delegate = HttpResponse delegate(HttpRequest req);

class ActionTester {
	HTTPServerRequest viberequest;
	HTTPServerResponse viberesponse;
	HttpRequest request;
	MemoryStream response_stream;
	ubyte[1000000] outputdata;
	SessionStore vibesessionstore;
	SessionStore sessionstore;
	string sessionID;

	this(Request_delegate handler) {
		vibesessionstore = new MemorySessionStore ();
		sessionstore = new MemorySessionStore ();
		Request(handler);
	}

	this(Request_delegate handler, string input) {
		vibesessionstore = new MemorySessionStore ();
		sessionstore = new MemorySessionStore ();
		Request(handler, input);
	}

	public void Request(Request_delegate handler) {
		InetHeaderMap headers;
		if(sessionID != null) {
			headers["Cookie"] = "session_id=" ~ sessionID;
		}
		viberequest = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST, headers);
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
			headers["Cookie"] = "session_id=" ~ sessionID;
		}

		auto inputStream = createInputStreamFromString(input);
		viberequest = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST, headers, inputStream);
		PopulateRequestJson();
	}

	private void PopulateRequestJson() {
		// NOTICE: Code lifted from vibe.d source handleRequest
		if (icmp2(viberequest.contentType, "application/json") == 0 || icmp2(viberequest.contentType, "application/vnd.api+json") == 0 ) {
			auto bodyStr = () @trusted { return cast(string)viberequest.bodyReader.readAll(); } ();
			if (!bodyStr.empty) viberequest.json = parseJson(bodyStr);
		}
	}

	private void CallHandler(Request_delegate handler) {
		SetRequestCookies();
		
		request = CreateHttpRequestFromVibeHttpRequest(viberequest, sessionstore);
		HttpResponse response = handler(request);

		PrepareVibeResponse();
		RenderVibeHttpResponseFromRequestAndResponse(viberesponse, request, response);

		sessionID = GetResponseSessionID();
	}

	private void PrepareVibeResponse() {
		for(int i = 0; outputdata[i] != 0; ++i) {
			outputdata[i] = 0;
		}
		response_stream = new MemoryStream(outputdata);
		viberesponse = createTestHTTPServerResponse(response_stream, vibesessionstore);
	}

	private void SetRequestCookies() {
		// NOTICE: Code lifted from vibe.d source handleRequest
		// use the first cookie that contains a valid session ID in case
		// of multiple matching session cookies
		auto pv = "cookie" in viberequest.headers;
		if (pv) parseCookies(*pv, viberequest.cookies);
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

	HttpResponse handleRequest(HttpRequest request) {
		HttpResponse response = new HttpResponse;
		called = true;
		return response;
	}
}

class JsonInputDummyHandler {
	bool receivedJson;
	
	this() {
		receivedJson = false;
	}

	HttpResponse handleRequest(HttpRequest request) {
		HttpResponse response = new HttpResponse;
		if(request.json["data"].integer == 4) {
			receivedJson = true;
		}
		return response;
	}
}

class SessionDummyHandler {
	HttpResponse handleRequest(HttpRequest request) {
		HttpResponse response = new HttpResponse;
		auto session = request.StartSession();
		session.set("testkey", "testvalue");
		response.writeBody("body", 200);
		return response;
	}
}

class RequestSessionDummyHandler {
	public bool sessionok;

	this() {
		sessionok = false;
	}

	HttpResponse handleRequest(HttpRequest request) {
		HttpResponse response = new HttpResponse;
		if(request.session) {
			auto id = request.session.get!string("testkey");
			if(id == "testvalue") {
				sessionok = true;
			}
		}
		response.writeBody("body", 200);
		return response;
	}
}

//Creating a tester with handler calls the handler.
unittest {
	auto dummy = new CallFlagDummyHandler();
	
	auto tester = new ActionTester(&dummy.handleRequest);

	assert(dummy.called);
}

//Creating a tester with json post data should give the handler access to the data.
unittest {
	auto dummy = new JsonInputDummyHandler();
	
	auto tester = new ActionTester(&dummy.handleRequest, "{ \"data\": 4 }");

	assert(dummy.receivedJson);
}

//When testing a handler that sets session values you should be able to read them
unittest {
	auto dummy = new SessionDummyHandler();
	
	auto tester = new ActionTester(&dummy.handleRequest);
	assertNotEqual(tester.GetResponseSessionID(), null);
	string value = tester.GetResponseSessionValue!string("testkey");
	assertEqual(value, "testvalue");
}

//Subsequent calls after session value is set should have that session in request
unittest {
	auto responsesessinohandler = new SessionDummyHandler();
	auto tester = new ActionTester(&responsesessinohandler.handleRequest);

	auto requestsessionhandler = new RequestSessionDummyHandler();
	tester.Request(&requestsessionhandler.handleRequest);

	requestsessionhandler = new RequestSessionDummyHandler();
	tester.Request(&requestsessionhandler.handleRequest);

	assert(requestsessionhandler.sessionok);
}
