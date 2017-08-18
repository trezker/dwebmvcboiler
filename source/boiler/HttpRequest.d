module boiler.HttpRequest;

import std.json;
import std.conv;
import std.stdio;
import vibe.http.session;
import vibe.http.server;
import vibe.data.json;

import boiler.helpers;
import boiler.HttpResponse;

class HttpRequest {
	private SessionStore sessionstore;
	Session session;
	JSONValue json;

	this(SessionStore sessionstore) {
		this.sessionstore = sessionstore;
	}

	void SetJsonFromString(string jsonstring) {
		json = parseJSON(jsonstring);
	}

	Session StartSession() {
		if(!session) {
			session = sessionstore.create();
		}
		return session;
	}

	void TerminateSession() {
		if(session) {
			sessionstore.destroy(session.id);
			session = Session.init;
		}
	}
}

HttpRequest CreateHttpRequestFromVibeHttpRequest(HTTPServerRequest viberequest, SessionStore sessionstore) {
	HttpRequest request = new HttpRequest(sessionstore);

	if(viberequest.json.type != Json.Type.undefined)
		request.SetJsonFromString(serializeToJsonString(viberequest.json));

	foreach (val; viberequest.cookies.getAll("session_id")) {
		request.session = sessionstore.open(val);
		if (request.session) break;
	}
	return request;
}

void RenderVibeHttpResponseFromRequestAndResponse(HTTPServerResponse viberesponse, HttpRequest request, HttpResponse response) {
	if(request.session) {
		viberesponse.setCookie("session_id", request.session.id);
	}
	viberesponse.writeBody(response.content, response.code);
}

//Create request with json
unittest {
	import std.stdio;
	
	auto sessionstore = new MemorySessionStore ();
	JSONValue json;
	json["key"] = "value";
	auto request = new HttpRequest(sessionstore);
	request.SetJsonFromString(json.toString);

	assertEqual(request.json["key"].str, "value");
}

//Request can start a session
unittest {
	auto sessionstore = new MemorySessionStore ();
	HttpRequest request = new HttpRequest(sessionstore);
	Session session = request.StartSession();
	assert(session);
	assert(request.session);
}

//Request can terminate session
unittest {
	auto sessionstore = new MemorySessionStore ();
	HttpRequest request = new HttpRequest(sessionstore);
	Session session = request.StartSession();
	request.TerminateSession();
	assert(!request.session);
}
