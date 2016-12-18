module boiler.server;

import std.algorithm;
import std.file;
import std.json;
import std.functional;
import std.conv;
import std.array;
import std.format;
import vibe.http.server;
import vibe.core.log;
import vibe.http.websockets : WebSocket;
import vibe.core.core : sleep;
import core.time;
import boiler.model;
import vibe.http.fileserver;

import application.application;

class Server {
private:
	Model_method[string][string] models;
	Application application;
public:
	bool setup() {
		application = new Application();
		if(!application.initialize()) {
			logInfo("Application initialization failed.");
			return false;
		}

		application.setup_models(models);
		return true;
	}

	void errorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error) {
		res.render!("error.dt", req, error);
	}

	void test(HTTPServerRequest req, HTTPServerResponse res) {
		res.render!("test.dt", req);
	}

	void get(HTTPServerRequest req, HTTPServerResponse res) {
		try {
			string path = req.path;
			auto splitpath = split(path, "/");
			if(splitpath.length < 4)
				return;
			string model = splitpath[2];
			string method = splitpath[3];
			if(model in models && method in models[model]) {
				models[model][method].call (req, res);
			}
		}
		catch(Exception e) {
			logInfo(e.msg);
		}
	}

	void ajax(HTTPServerRequest req, HTTPServerResponse res) {
		try {
			string model = req.json["model"].to!string;
			string method = req.json["method"].to!string;
			if(model in models && method in models[model]) {
				models[model][method].call (req, res);
			}
			else {
				res.writeJsonBody("Model/method does not exist");
			}
		}
		catch(Exception e) {
			logInfo(e.msg);
		}
	}
	
	void page(HTTPServerRequest req, HTTPServerResponse res) {
		try {
			string path = application.rewrite_path(req);
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
