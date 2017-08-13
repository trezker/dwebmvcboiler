module boiler.HttpRequest;

import std.json;
import boiler.helpers;
import std.conv;

class HttpRequest {
	JSONValue json;

	this(string jsonstring) {
		json = parseJSON(jsonstring);
	}
}

//Create request with json
unittest {
	import std.stdio;
	
	JSONValue json;
	json["key"] = "value";
	auto request = new HttpRequest(json.toString);

	assertEqual(request.json["key"].str, "value");
}