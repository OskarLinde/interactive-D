module interactive.run;

import std.stdio;
import interactive.eval;
import interactive.modules;
import interactive.parser;
import interactive.settings;

void main() {
	writefln("Hello "~username~"! Welcome to Interactive D version 0.0.2");
	writefln("Type \"help\" for more information. Ctrl-D to exit.");
	
	while(1) {
		writef(">>> ");
		
		auto str = readln();
		if (!str)
			break;
		str = str[0..$-1]; // strip \n
		
		try {
			checkAllModificationDates();
			interactive.parser.executeCommand(str);
		} catch(Exception e) {
			writefln(e);
		}
	}
	writefln();
	
	interactive.settings.cleanup();
}