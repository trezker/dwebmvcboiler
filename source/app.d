import core.stdc.stdlib;
import std.functional;
import vibe.appmain;
import vibe.core.core;
import vibe.core.log;
import vibe.http.router;
import vibe.http.fileserver;
import boiler.server;
import vibe.http.websockets : handleWebSockets;

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
	settings.errorPageHandler = toDelegate(&server.errorPage);
	settings.sessionStore = new MemorySessionStore;

	auto router = new URLRouter;
	router.get("/test", &server.test);
	router.post("/ajax*", &server.ajax);
	router.get("/ws", handleWebSockets(&server.websocket));
	router.get("/source/*", serveStaticFiles("./public/"));
/*
	auto pagesettings = new HTTPFileServerSettings;
	pagesettings.preWriteCallback = &server.preWriteCallback;
	router.get("/js/*", serveStaticFiles("./public/", pagesettings));
	router.get("/css/*", serveStaticFiles("./public/", pagesettings));
*/
	router.get("/*", &server.page);

	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
