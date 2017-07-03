module boiler.httphandlertester;

import boiler.model;
import vibe.inet.url;
import vibe.http.server;
import vibe.stream.memory;
import vibe.stream.operations;
import std.json;
import std.stdio;
import std.string;

class HTTPHandlerTester {
	HTTPServerResponse res;
	string rawResponse;
	string[] lines;
	MemoryStream response_stream;
	ubyte[1000000] data;

	this(Request_delegate handler) {
		call_handler(handler);
		read_response();
	}

	private void call_handler(Request_delegate handler) {
		HTTPServerRequest req = createTestHTTPServerRequest(URL("http://localhost/test"), HTTPMethod.POST);//, InetHeaderMap headers, InputStream data = null)
		response_stream = new MemoryStream(data);
		res = createTestHTTPServerResponse(response_stream);//SessionStore session_store = null)
		handler(req, res);
		res.finalize;
	}

	private void read_response() {
		response_stream.seek(0);
 		rawResponse = response_stream.readAllUTF8();
 		lines = rawResponse.splitLines();
	}

	public JSONValue get_reponse_json() {
		return parseJSON(lines[$-1]);
	}
}