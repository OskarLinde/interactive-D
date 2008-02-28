module interactive.value;

import std.stdarg;
import std.format;
import std.utf;

struct Value {
	void[] value;
	//TypeInfo type;
	char[] typestr;
	
	T to(T)() { return *(cast(T*)value.ptr);}
	/*
	char[] toString() {
		TypeInfo[] arg1 = [type];
		va_list arg2 = cast(va_list) value.ptr;

		char[] ret;
		void PUTC(dchar c) { ret.encode(c); }
		std.format.doFormat(&PUTC, arg1, arg2);
		return ret;
	}*/
}
