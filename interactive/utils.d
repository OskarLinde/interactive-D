module interactive.utils;

bool beginsWith(char[] a, char[] b) {
	if (a.length < b.length) return false;
	return a[0..b.length] == b;
}

void swapoutIndex(T)(inout T[] arr, uint ix) { arr[ix] = arr[$-1]; arr.length = arr.length-1; }
void setAdd(T)(inout T[] arr, T v) { foreach(a; arr) if (a == v) return; arr ~= v; }
bool contains(T)(T[] arr, T value) { foreach(a; arr) if (a == value) return true; return false;}

template RetTy(FunTy,T) { alias typeof(FunTy(T)) RetTy; }
RetTy!(FunTy,T)[] map(T,FunTy)(T[] arr, FunTy fun) { 
	auto ret = new RetTy!(FunTy,T)[arr.length]; 
	foreach(i,a; arr) ret[i] = fun(a); 
	return ret;
}

void swapout(T)(inout T[] arr, T v) { 
	foreach(i, a; arr) 
		if (a == v) { 
			arr.swapoutIndex(i);
			return;
		}
}