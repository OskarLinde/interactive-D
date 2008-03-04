module interactive.readline;

version=Readline;

version(Readline) {
	
	import std.string;
	
	version (build) {
	    pragma(link, "readline");
	}
	
	extern(C) char* readline(char*);
	extern(C) int add_history(char*);

	char[] readln(char[] prompt) {
		char *s = readline(toStringz(prompt));
		if (!s)	return null;
		char[] ret = toString(s);
		if (ret.length) add_history(s);
		return ret;
	}
	
} else {
	
	import std.stdio;
	
	char[] readln(char[] prompt) {
		writef(prompt);
		char[] s = std.stdio.readln();
		if (s.length < 1) return s;
		return s[0..$-1]; // strip \n
	}
	
}