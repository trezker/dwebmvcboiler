module boiler.server;

import std.algorithm;
import std.file;
import std.json;
import std.functional;
import std.conv;
import std.array;
import std.format;
import std.stdio;
import core.time;
import vibe.http.server;
import vibe.core.log;
import vibe.http.websockets : WebSocket;
import vibe.core.core : sleep;
import vibe.http.fileserver;

import boiler.Ajax;
import boiler.HttpRequest;
import boiler.HttpResponse;
import application.application;

class Server {
private:
	Application application;
	Ajax ajax;
	SessionStore sessionstore;
public:
	bool setup() {
		ajax = new Ajax();
		application = new Application();
		application.SetupAjaxMethods(ajax);
		sessionstore = new MemorySessionStore ();
		return true;
	}

	void ErrorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error) {
		string filepath = "pages/error.html";
		string page = filepath.readText;

		page = page.replace("#{error.message}", error.message);
		page = page.replace("#{error.code}", to!string(error.code));

		res.writeBody(page, "text/html; charset=UTF-8");
	}

	void PerformAjax(HTTPServerRequest req, HTTPServerResponse res) {
		try {
			HttpRequest request = CreateHttpRequestFromVibeHttpRequest(req, sessionstore);
			HttpResponse response = ajax.Perform (request);
			RenderVibeHttpResponseFromRequestAndResponse(res, request, response);
		}
		catch(Exception e) {
			logInfo(e.msg);
		}
	}
	
	void Page(HTTPServerRequest req, HTTPServerResponse res) {
		try {
			HttpRequest request = CreateHttpRequestFromVibeHttpRequest(req, sessionstore);
			string path = application.RewritePath(request);
			if(path == "/") {
				path = "/index";
			}
			else {
				path = path[1..$];
			}
			string filepath = format("pages/%s.html", path);
			res.writeBody(filepath.readText, "text/html; charset=UTF-8");
		}
		catch(Exception e) {
			logInfo(e.msg);
		}
	}

	void websocket(scope WebSocket socket) {
		int counter = 0;
		logInfo("Got new web socket connection.");
		while (true) {
			sleep(1.seconds);
			if (!socket.connected) break;
			counter++;
			logInfo("Sending '%s'.", counter);
			socket.send(counter.to!string);
		}
		logInfo("Client disconnected.");
	}

	void preWriteCallback(scope HTTPServerRequest req, scope HTTPServerResponse res, ref string path) {
		logInfo("Path: '%s'.", path);
		logInfo("req.path: '%s'.", req.path);
	};

	void daemon() {
		while (true) {
			sleep(1.seconds);
		}
	}
}
