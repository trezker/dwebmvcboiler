module application.FindCity;

import std.json;
import std.stdio;
import std.conv;
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
			json["cities"] = "[]".parseJSON();
			foreach(City city; result) {
				JSONValue jsoncity;
				jsoncity["name"] = city.name;
				jsoncity["latitude"] = city.latitude;
				jsoncity["longitude"] = city.longitude;
				json["cities"].array ~= jsoncity;
			}

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

//FindCity with partial search should find complete cities.
unittest {
	import application.testhelpers;

	Cities cities = new Cities;
	City city;
	city.name = "Stockholm";
	city.latitude = 1.2;
	city.longitude = 2.3;

	City city2;
	city2.name = "Stockhult";
	city2.latitude = 3.4;
	city2.longitude = 4.5;

	cities.cities.Insert("Stockholm", city);
	cities.cities.Insert("Stockhult", city2);
	FindCity findCity = new FindCity(cities);

	JSONValue jsoninput;
	jsoninput["search"] = "Stock";

	ActionTester tester = new ActionTester(&findCity.Perform, jsoninput.toString);

	JSONValue json = tester.GetResponseJson();
	assert(json["success"] == JSONValue(true));
	assert(json["cities"][0]["name"] == JSONValue("Stockholm"));
	assert(json["cities"][0]["latitude"] == JSONValue(1.2));
	assert(json["cities"][0]["longitude"] == JSONValue(2.3));
	assert(json["cities"][1]["name"] == JSONValue("Stockhult"));
	assert(json["cities"][1]["latitude"] == JSONValue(3.4));
	assert(json["cities"][1]["longitude"] == JSONValue(4.5));
}
