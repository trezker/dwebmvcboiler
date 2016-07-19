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
import mondo;
import boiler.model;
import vibe.http.fileserver;

import boiler.user;

class Server {
private:
	Mongo mongo;
	User_model user_model;
	Model_method[string][string] models;
	
public:
	bool setup() {
		if(!databaseSetup()) {
			logInfo("Database setup failed.");
			return false;
		}

		user_model = new User_model;
		user_model.setup(mongo, models);
		return true;
	}

	bool databaseSetup() {
		try {
			mongo = new Mongo("mongodb://localhost");
		}
		catch(Exception e) {
			logInfo(e.msg);
		}
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
			string model = req.json.model.to!string;
			string method = req.json.method.to!string;
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
			string path = req.path;
			if(path == "/") {
				path = "/index";
			}
			else {
				path = req.requestURL[1..$];
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
