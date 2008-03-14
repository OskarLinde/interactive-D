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
	static evalnum = 0;
	evalnum++;
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
	
	char[] srcfile = format("%s/caller%03d.d",tmpdir,evalnum);
	std.file.write(srcfile,
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
			if (__r.ptr > cast(void*)&__ret - 100000) {
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
	
	char[] libfile = format("%s/caller%03s%s\0",tmpdir,evalnum,binext);
	libfile = libfile[0..$-1]; // strip off zero-termination
	
	char[][] deps = null;
	try {
		build([srcfile],libfile,deps);
	} catch(BuildException e) {
		if (e.toString() == "Failed to compile "~srcfile)
			throw new BuildException("Failed to evaluate");
		throw e;
	}
	//}
	
	Value function(Value[]) func;
	void *handle;
	
	//{	scope v = new Timer("dyld");
	handle = dlopen(libfile.ptr,RTLD_NOW|RTLD_GLOBAL);
	if (!handle) {
		throw new Exception(std.string.format("dlopen(\""~libfile~"\"): %s",std.string.toString(dlerror())));
	}
	auto funcptr = dlsym(handle,format("_D9caller%03s5entryFAS11interactive5value5ValueZS11interactive5value5Value\0",
	                evalnum).ptr);
	if (!funcptr) {
		throw new Exception(format("dlsym: %s",std.string.toString(dlerror())));
	}
	
	func = cast(Value function (Value[])) funcptr;
	//}
	
	Value val;
	//{   scope v = new Timer("calling"); 
		val = func(argvalues);
	//}
	
	// Hack to work around TypeInfo.toString bug for templates (not complete)
	int p = val.typestr.rfind(".");
	int q = val.typestr.find("!");
	if (p > -1 && q > -1 && p < val.typestr.length) {
		int l = val.typestr.length-p-1;
		if (val.typestr[q-l..q] == val.typestr[p+1..$]) 
			val.typestr = val.typestr[0..p];
	}
	
	//writefln(" * ",str," = ",toString(val), " (",val.typestr,")");	
	
	//{	scope v = new Timer("unloading");
	
		dlclose(handle);
	//}


	return val;
	/*
	writefln(" * " ~ str ~" = ", *(cast(int *) val.value), " (",val.typestr,")");*/
	//}	
}