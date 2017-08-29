module application.Trie;

import std.stdio;
import boiler.helpers;

class Trie(V) {
	Trie[char] children;
	V[] values;

	this() {
		values = [];
	}

	void Insert(string key, V value) {
		if(key.length == 0) {
			values ~= value;
			return;
		}

		if(key[0] in children) {
			children[key[0]].Insert(key[1..$], value);
		}
		else {
			children[key[0]] = new Trie;
			children[key[0]].Insert(key[1..$], value);
		}
	}

	V[] Exact(string key) {
		if(key.length == 0) {
			return values;
		}

		if(key[0] in children) {
			return children[key[0]].Exact(key[1..$]);
		}

		return [];
	}

	V[] WithPrefix(string key) {
		if(key.length == 0) {
			V[] result = [];
			result ~= values;
			foreach(Trie t; children) {
				result ~= t.WithPrefix("");
			}
			return result;
		}

		if(key[0] in children) {
			return children[key[0]].WithPrefix(key[1..$]);
		}

		return [];
	}
}

//Trie can find an inserted value.
unittest {
	auto root = new Trie!int;
	root.Insert("a", 1);

	assertEqual(root.Exact("a"), [1]);
}

//Trie can find an inserted value.
unittest {
	auto root = new Trie!int;
	root.Insert("a", 1);
	root.Insert("as", 2);

	assertEqual(root.Exact("a"), [1]);
	assertEqual(root.Exact("as"), [2]);
}

//Trie can complete keys from a prefix.
unittest {
	auto root = new Trie!int;
	root.Insert("a", 1);
	root.Insert("as", 2);

	assertEqual(root.WithPrefix("a"), [1, 2]);
}