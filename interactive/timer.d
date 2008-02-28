module interactive.timer;

import std.stdio;

struct timeval {
	uint sec;
	int usec;
}

extern(C) int gettimeofday(timeval *tf, void *tpz);

class Timer {
	char[] str;
	timeval start;
	this(char[] str) { this.str = str; gettimeofday(&start, null); }
	~this() {
		timeval end;
		gettimeofday(&end, null);
		ulong diff = (end.sec - start.sec) * 1_000_000 + end.usec - start.usec;
		writefln("%s: %.1f ms", str, diff/1000.0);
	}
}