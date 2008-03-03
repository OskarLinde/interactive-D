module interactive.eval;

import std.file;
import std.stdio;
import std.string;

import interactive.dlfcn;
import interactive.builder;
import interactive.value;
import interactive.timer;
import interactive.modules;
import interactive.settings;

import interactive.allstd; // ough

Value[char[]] variables;

import std.typeinfo.ti_Adouble;

char[] toString(Value v) {
	if(v.typestr == "void" || v.typestr == "")
		return "void";
	if(v.typestr != "char[]")
		v = expression("std.string.format(\"%s\",__v)",["__v"[]:v]);
	return v.to!(char[]);
}
//import std.typeinfo.ti_Areal;
static this() {
	void[] t = new void[5];
	auto u = t.dup;
	u[] = t[];
	
	bool b = 1;
	assert(b);
	assert(b,"abc");
	
	auto c = typeid(real);
	auto d = typeid(real[]);
}

Value expression(char[] str, Value[char[]] args = variables) {
	//{ scope vv = new Timer("Eval total"); 
	//{ scope v = new Timer("Writing file"); 
	
/*	char[][] parts = tokenize(str);
	foreach(inout p; parts) {
		if (auto p in args)
	}
*/

	char[] arglist;
	char[] callstr;
	Value[] argvalues;
	int i = 0;
	foreach(n,v; args) {
		arglist ~= "ref " ~ v.typestr ~ " " ~ n ~", ";
		callstr ~= format("*(cast(%s*) args[%s].value.ptr), ",v.typestr,i);
		argvalues ~= v;
		i = i + 1;
	}
	
	if (arglist.length > 0) {
		arglist = arglist[0..$-2]; // strip last ", ";
		callstr = callstr[0..$-2];
	}
	
	char[] imports;
	foreach(m; forcedModules)
	imports ~= "import " ~ m ~ ";\n";
	
	std.file.write(tmpdir ~ "/caller.d",
	`import interactive.value;
`~imports~`
	
Value entry(Value[] args) {
	return call(`~callstr~`);
}

Value call(`~arglist~`) {
	Value __ret;
	static if (is(typeof((`~str~`)) == void)) {
#line 1 "input"
		(`~str~`);
	} else { 
#line 1 "input"
		auto __t = (` ~ str ~ `);
		static if (!is(typeof(typeof(__t).init) == typeof(__t)))
			auto __r = __t[];
		else
			auto __r = __t;
		static if (is(typeof(__r.ptr)) && is (typeof(__r.dup))) {
			// On stack or in static data segment
			if (__r.ptr > cast(void*)0xB0000000 || __r.ptr < cast(void*)0x100000) {
				__r = __r.dup;
			}
		}
		__ret.value = new void[__r.sizeof];
		__ret.value[] = (cast(void *)&__r)[0..__r.sizeof];
		//ret.type = typeid(typeof(__r));
		__ret.typestr = typeid(typeof(__r)).toString.dup;
	}
	return __ret;
}
`);
	//}
	//{ 	scope v = new Timer("Build total");
	
	char[] libfile = tmpdir ~ "/caller" ~ binext ~ \0;
	libfile = libfile[0..$-1]; // strip off zero-termination
	
	char[][] deps = null;
	try {
		build([tmpdir~"/caller.d"],libfile,deps);
	} catch(BuildException e) {
		if (e.toString() == "Failed to compile "~tmpdir~"/caller.d")
			throw new BuildException("Failed to evaluate");
		throw e;
	}
	//}
	
	Value function(Value[]) func;
	void *handle;
	
	//{	scope v = new Timer("dyld");
	handle = dlopen(libfile.ptr,RTLD_NOW);
	if (!handle) {
		throw new Exception(std.string.format("dlopen(\""~libfile~"\"): %s",std.string.toString(dlerror())));
	}
	auto funcptr = dlsym(handle,"_D6caller5entryFAS11interactive5value5ValueZS11interactive5value5Value");
	if (!funcptr) {
		throw new Exception(format("dlsym: %s",std.string.toString(dlerror())));
	}
	
	func = cast(Value function (Value[])) funcptr;
	//}
	
	Value val;
	//{   scope v = new Timer("calling"); 
		val = func(argvalues);
	//}
	if (val.typestr.length > 11 && val.typestr[$-11..$] == ".ArraySlice")
		val.typestr = val.typestr[0..$-11];
	
	//writefln(" * ",str," = ",toString(val), " (",val.typestr,")");	
	
	//{	scope v = new Timer("unloading");
	
		dlclose(handle);
	//}


	return val;
	/*
	writefln(" * " ~ str ~" = ", *(cast(int *) val.value), " (",val.typestr,")");*/
	//}	
}