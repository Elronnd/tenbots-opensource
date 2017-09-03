// This entire thing is heavily based on https://p0nce.github.io/d-idioms/#Embed-a-dynamic-library-in-an-executable
module assetlib;


private struct Fdesc {
	string fname;
	ubyte[] data;
	bool fexists;
	string newfname;
}

private Fdesc[string] fdata;


pragma(inline, true) public void regasset(string id, string fpath)() {
	import std.algorithm: splitter;
	import std.path: dirSeparator;
	import std.array: array;

	fdata[id] = Fdesc(array(splitter(fpath, dirSeparator))[$-1], cast(ubyte[])import(fpath));
}

pragma(inline, true) public const(ubyte[]) assetdata(string id)() {
	return fdata[id].data;
}

pragma(inline, true) public const(string) assetfname(string id)() {
	return fdata[id].fname;
}

public string assetpath(string id)() {
	if (!fdata[id].fexists) {
		import std.string: lastIndexOf;
		import std.path: tempDir, buildPath;
		import std.uuid: randomUUID;
		import std.file: write;

		string path, fname = getfname!(id);

		// Keep the extension.  So if it's something like "foo.barbaz.ogg", change it to "foo.barbaz-someuniqueid.ogg"
		auto idx = lastIndexOf(fname, ".");

		if (idx != -1) {
			path = fname[0 .. idx] ~ '-' ~ randomUUID().toString ~ '.' ~ fname[idx+1 .. $];
		} else {
			// No file extension, so "fooBar" just turns to "fooBar-someuniqueid"
			path = fname ~ '-' ~ randomUUID().toString;
		}

		path = buildPath(tempDir(), path);

		write(path, getdata!(id));

		fdata[id].fexists = true;
		fdata[id].newfname = path;
	}

	return fdata[id].newfname;
}

// delete all the tmp files
static ~this() {
	import std.file: remove;

	foreach (file; fdata.byValue()) {
		if (file.fexists) {
			remove(file.newfname);
			file.fexists = false; // idk in case something really weird happens
		}
	}
}
