module interactive.settings;

import std.string;
import std.process;
import std.file;

import interactive.utils;

version(DigitalMars) {static assert(0,"Sorry, DMD is currently unsupported. Try GDC."); }

version(darwin) {
	private char[] home;
	char[] tmpdir;
	char[] username;
	
	extern(C) char* getenv(char *name);
	extern(C) int getpid();
	
	static this() {
		home = toString(getenv("HOME"));
		// Note cleanup() below!!!
		tmpdir = format("/tmp/InteractiveD-%s-%s",toString(getenv("USER")),getpid());
		system("mkdir "~tmpdir ~ " >> /dev/null");
		system("id -P | cut -d: -f8 > "~tmpdir~"/name");
		username = cast(char[])std.file.read(tmpdir~"/name");
		int t = username.find(" ");
		if (t > -1) username = username[0..t];
	}
	
	void cleanup() {
		system("rm -rf "~tmpdir ~ " >> /dev/null");
	}
	
	//char[] bindir = ".";
	char[] binext = ".osxi386";
	
	version=COMPILER_GDC;

	int link(char[][] files, char[] outfile) {
		return system("gcc "~join(files," ")~" -bundle -Wl,-flat_namespace "
		              "-undefined suppress -o " ~ outfile);
	}

	bool isSystemFile(char[] file) {
		return file.find("lib/gcc") > -1;
	}
} else version(linux) {
	
	version (build) {
	    pragma(link, "dl");
	    pragma(link, "curses");
	}
	
	private char[] home;
	char[] tmpdir;
	char[] username;
	
	extern(C) char* getenv(char *name);
	extern(C) int getpid();
	
	static this() {
		home = toString(getenv("HOME"));
		// Note cleanup() below!!!
		tmpdir = format("/tmp/InteractiveD-%s-%s",toString(getenv("USER")),getpid());
		system("mkdir "~tmpdir ~ " >> /dev/null");
		system("grep ^`whoami`: /etc/passwd | cut -d: -f5 | cut -d, -f1 > "~tmpdir~"/name");
		username = cast(char[])std.file.read(tmpdir~"/name");
		int t = username.find(" ");
		if (t > -1) username = username[0..t];
	}
	
	void cleanup() {
		system("rm -rf "~tmpdir ~ " >> /dev/null");
	}
	
	//char[] bindir = ".";
	char[] binext = ".lnxi386";
	
	version=COMPILER_GDC;
	
	int link(char[][] files, char[] outfile) {
		return system("gcc "~join(files," ")~" -shared -o " ~ outfile);
	}

	bool isSystemFile(char[] file) {
		return file.find("lib/gcc") > -1;
	}
}
else { static assert(0,"Unsupported platform"); }

version(COMPILER_GDC) {
	int compile(char[] file, char[] outfile, inout char[][] deps) {
		deps.length = 0;
		int s = system("gdc --d-verbose -fPIC -c -I/usr/include/d -I" ~ home ~ "/d/include/d " ~ file ~ " -o "~outfile~" > "~tmpdir~"/DEPS");
		if (s) return s;
		foreach(l; (cast(char[])std.file.read(tmpdir~"/DEPS")).splitlines()) {
			if (l.beginsWith("import ")) {
				int a = l.find('(');
				int b = l.rfind(')');
				if (a == -1 || b == -1)
					continue;
				deps ~= l[a+1..b];
			}
		}
		return s;
	}
} else { static assert(0,"Unsupported compiler"); }
