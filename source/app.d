import std.functional;
import core.stdc.stdlib;
import vibe.appmain;
import vibe.core.core;
import vibe.core.log;
import vibe.http.router;
import vibe.http.fileserver;
import vibe.http.websockets : handleWebSockets;

import boiler.server;

shared static this() {
	auto server = new Server;

	runTask({
		if(!server.setup()) {
			exit(-1);
		}
	});
	runTask({
		server.daemon();
	});
	
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	settings.errorPageHandler = toDelegate(&server.ErrorPage);
	settings.sessionStore = new MemorySessionStore;

	auto router = new URLRouter;
	router.post("/ajax*", &server.PerformAjax);
	router.get("/ws", handleWebSockets(&server.websocket));
	router.get("/source/*", serveStaticFiles("./public/"));
	router.get("/*", &server.page);

	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
