module application.FindCity;

import std.json;
import std.stdio;
import vibe.http.server;

import boiler.ActionTester;
import boiler.helpers;
import boiler.HttpRequest;
import boiler.HttpResponse;

import application.Cities;

class FindCity: Action {
	Cities cities;

	this(Cities cities) {
		this.cities = cities;
	}

	HttpResponse Perform(HttpRequest req) {
		HttpResponse res = new HttpResponse;
		try {
			string search = req.json["search"].str;

			City[] result = cities.Search(search);

			JSONValue json;
			json["success"] = true;
			res.writeBody(json.toString, 200);
		}
		catch(Exception e) {
			JSONValue json;
			json["success"] = false;
			res.writeBody(json.toString, 200);
		}
		return res;
	}
}

//Logout should succeed and session should not contain a user id
unittest {
	import application.testhelpers;

	Cities cities = new Cities;
	City city;
	city.name = "Stockholm";
	city.latitude = 1;
	city.longitude = 2;

	cities.cities.Insert("Stockholm", city);
	FindCity findCity = new FindCity(cities);

	JSONValue jsoninput;
	jsoninput["search"] = "Stock";

	ActionTester tester = new ActionTester(&findCity.Perform, jsoninput.toString);

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(true));
}
