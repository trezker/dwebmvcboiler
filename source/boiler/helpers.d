module boiler.helpers;

import std.algorithm : fill;
import std.ascii : letters, digits;
import std.conv : to;
import std.random : randomCover, rndGen;
import std.range : chain;

string get_random_string(uint length) {
	auto asciiLetters = to!(dchar[])(letters);
    auto asciiDigits = to!(dchar[])(digits);

    dchar[] key;
    key.length = length;
    fill(key[], randomCover(chain(asciiLetters, asciiDigits), rndGen));
    return to!(string)(key);
}
