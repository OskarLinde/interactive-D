module interactive.parser;

import std.stdio;
import std.string;
import std.ctype;

import interactive.utils;
import interactive.modules;
import interactive.eval;


void executeCommand(char[] str) {
	str = strip(str);
	
	if (str == "") {
		
	} else if (str == "help") {
		writefln("Interactive D");
		writefln("Syntax:");
		writefln(" <expression>               evaluate <expression>, store result in '_'");
		writefln(" <variable> = <expression>  evaluate <expression>, store result in <variable>");
		writefln(" who                        list variables");
		writefln(" import <module>            import module");
		writefln(" imports                    list imported modules");
		
	} else if (str.beginsWith("import ")) {
		importModule(str[7..$],true);
		
	} else if (str == "imports") {
		writefln("Imports:");
		foreach(m; forcedModules)
			writefln(" ", m);
			
	} else if (str == "who") {
		writefln("Variables:");
		foreach(name, value; variables)
			writefln(" %s = %s (%s)",name, interactive.eval.toString(value), value.typestr);
			
	} else if (str in variables) {
		writefln(" %s = %s (%s)", str, interactive.eval.toString(variables[str]),
				 variables[str].typestr);
		
	} else {
		char[] var = "_";
		
		int p = str.find("=");
		if (p > -1) {
			char[] v = strip(str[0..p]);
			if (isValidIdentifier(v)) {
				var = v;
				str = str[p+1..$];
			}
		}
		
		auto val = interactive.eval.expression(str);
		
		if (val.typestr != "" && val.typestr != "void") {
			variables[var] = val;
			if (var == "_")
				writefln(" %s (%s)", interactive.eval.toString(val), val.typestr);
			else
				writefln(" %s = %s (%s)", var, interactive.eval.toString(val), val.typestr);
		}
	}
}


bool isValidIdentifier(char[] str) {
	if (str.length == 0)
		return false;
	bool firstChar(char c) { return c == '_' || isalpha(c) || !isascii(c); }
	bool otherChars(char c) { return firstChar(c) || isdigit(c); }
	if (!firstChar(str[0]))
		return false;
	foreach(char c; str)
		if (!otherChars(c))
			return false;
	return true;
}
