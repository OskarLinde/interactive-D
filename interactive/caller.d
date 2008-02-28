import value;

	
Value entry(Value[] args) {
	return call();
}

Value call() {
	Value __ret;
	static if (is(typeof((1+1)) == void)) {
#line 1 "input"
		(1+1);
	} else { 
#line 1 "input"
		auto __t = (1+1);
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
