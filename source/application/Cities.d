module application.Cities;

import std.file;
import std.csv;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;

import application.Trie;

// http://download.geonames.org/export/dump/
struct City
{
	int geonameid;            // integer id of record in geonames database
	string name;              // name of geographical point (utf8) varchar(200)
	string asciiname;         // name of geographical point in plain ascii characters, varchar(200)
	string alternatenames;    // alternatenames, comma separated, ascii names automatically transliterated, convenience attribute from alternatename table, varchar(10000)
	double latitude;          // latitude in decimal degrees (wgs84)
	double longitude;         // longitude in decimal degrees (wgs84)
	string feature_class;     // see http://www.geonames.org/export/codes.html, char(1)
	string feature_code;      // see http://www.geonames.org/export/codes.html, varchar(10)
	string country_code;      // ISO-3166 2-letter country code, 2 characters
	string cc2;               // alternate country codes, comma separated, ISO-3166 2-letter country code, 200 characters
	string admin1_code;       // fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
	string admin2_code;       // code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80) 
	string admin3_code;       // code for third level administrative division, varchar(20)
	string admin4_code;       // code for fourth level administrative division, varchar(20)
	int    population;        // bigint (8 byte int) 
	string elevation;         // in meters, integer
	string dem;               // digital elevation model, srtm3 or gtopo30, average elevation of 3''x3'' (ca 90mx90m) or 30''x30'' (ca 900mx900m) area in meters, integer. srtm processed by cgiar/ciat.
	string timezone;          // the iana timezone id (see file timeZone.txt) varchar(40)
	string modification_date; // date of last modification in yyyy-MM-dd format
}
/*
4125402	
Paris	
Paris	
Paris,
Parizh,barys,parys,perisa,pyrs  arknsas,Париж,Парис,باريس,پاریس,پیرس، آرکنساس,पेरिस	
35.29203	
-93.72992	
P	
PPL	
US	

AR	
083	
93372	

3443	
123	
128	
America/Chicago	
2017-05-23
*/

class Cities {
	Trie!City cities;

	this() {
		cities = new Trie!City;
	}

	void Load() {
		string fileContent = readText("resources/cities1000.txt");
		fileContent = fileContent.replace("\"", "");
		auto csvCities = csvReader!City(fileContent, '\t');
		foreach(City city; csvCities) {
			cities.Insert(toLower(city.name), city);
		}
	}

	City[] Search(string search) {
		return cities.WithPrefix(toLower(search));
	}
}

//Lookup city by name
/*
unittest {
	Cities cities = new Cities();

	auto r = cities.cities.Exact("Stockholm");
	writeln(r);
}
*/
unittest {
	Cities cities = new Cities();
	cities.Load();
	writeln(cities.Search("Stock"));
}
