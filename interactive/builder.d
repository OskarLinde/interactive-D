module interactive.builder;

import std.string : replace;

import interactive.settings;
import interactive.timer;
import interactive.utils;

class BuildException : Exception {
	this(char[] s) { super(s) ;}
}

void build(char[][] files, char[] outfile, inout char[][] fullDeps) {
	fullDeps.length = 0;
	char[][] objfiles;
	
	foreach(f; files) {
		//scope v = new Timer("Compiling "~f);
		char[][] deps;
		char[] objfile = tmpdir~"/"~sourcetoobj(f);
		auto s = compile(f,objfile,deps);
		objfiles ~= objfile;
		stripSystemDeps(deps);
		foreach(d; deps)
			fullDeps.setAdd(d);
		if (s)
			throw new BuildException("Failed to compile " ~ f);
	}

	int s;
	//{
	//	scope v = new Timer("Linking "~outfile);
		s = link(objfiles, outfile);
	//}
	if (s)
		throw new BuildException("Failed to link " ~ outfile);
}


void stripSystemDeps(inout char[][] deps) {
	for(uint i = 0; i < deps.length;) {
		if (isSystemFile(deps[i]))
			deps.swapoutIndex(i);
		else
			i++;
	}
}

char[] sourcetoobj(char[] s) { 
	char[] o = s.replace("/",".");
	if (o.ptr == s.ptr)
		o = o.dup;
	o[$-1] = 'o';
	return o;
}
