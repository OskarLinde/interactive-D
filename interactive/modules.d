module interactive.modules;

import std.file;
import std.date;
import std.string;
import std.stdio;
import interactive.dlfcn;

import interactive.utils;
import interactive.builder;
import interactive.settings;

void*[char[]] handles;
char[][][char[]] sourceDeps;
d_time[char[]] creationTime;

char[][] forcedModules;       // modules loaded by the user
char[][][char[]] moduleDeps;  // module dependencies
char[][][char[]] moduleRDeps; // reverse dependencies


char[] moduleMangledName(char[] name) {
	char[] ret;
	char[][] parts = name.split(".");
	foreach(p; parts) 
		ret ~= format("%s%s",p.length,p);
	return ret;
}

void checkAllModificationDates() {
	char[][] dirtyModules;
	
	foreach(m, dep; sourceDeps) {
		d_time cTime = creationTime[m];
		foreach(d; dep) {
			if (getModificationTime(d) > cTime) {
				dirtyModules ~= m;
			}
		}
	}
	
	for (int i = 0; i < dirtyModules.length; i++) {
		char[] m = dirtyModules[i];
		if (m in moduleRDeps) {
			foreach(r; moduleRDeps[m]) {
				dirtyModules.setAdd(r);
			}
		}
	}
	
	foreach_reverse(m; dirtyModules) {
		unloadModule(m);
	}
	
	foreach(m; dirtyModules) {
		if (forcedModules.contains(m)) {
			writefln("Recompiling module ",m);
			importModule(m,1);
		}
	}
}


char[] sourceFromModule(char[] moduleName) {
	return moduleName.replace(".","/") ~ ".d";
}


char[] moduleFromSource(char[] source) {
	return source.replace("/",".")[0..$-2];
}


void importModule(char[] moduleName, bool forced) {
	scope(success) if (forced) forcedModules.setAdd(moduleName);

	if (moduleName.beginsWith("std.")) // BUG if moduleName is missing
		return;
	if (moduleName in handles) // already imported
		return;
	
	char[][] srcDeps;
	char[] modFile = tmpdir ~ "/" ~ moduleName ~ binext;
	
	interactive.builder.build([sourceFromModule(moduleName)], 
	              			modFile,
	              			srcDeps);
	
	char[][] modDeps = map(srcDeps, (char[] s) { return moduleFromSource(s); });
	
	// HMM?
	srcDeps.setAdd(sourceFromModule(moduleName));
	
	moduleDeps[moduleName] = modDeps;
	sourceDeps[moduleName] = srcDeps;
	
	foreach(d; modDeps) {
		if (!(d in moduleRDeps))
			moduleRDeps[d] = null;
		moduleRDeps[d].setAdd(moduleName);
	}
	
	// BUG: cyclic dependencies => infinite loop
	foreach(m; modDeps) {
		importModule(m, false);
	}
	
	void *handle;
	
	//{	scope v = new Timer("dyld");
	handle = dlopen(toStringz(modFile),RTLD_NOW|RTLD_GLOBAL);
	if (!handle) {
		throw new Exception(std.string.format("dlopen(\"%s\"): %s", 
		                                      modFile, std.string.toString(dlerror())));
	}
	
	auto funcptr = dlsym(handle,("_D"~moduleMangledName(moduleName)~"11_staticCtorFZv\0").ptr);
	if (funcptr) {
		auto func = cast(void function ()) funcptr;
	
		func();
	}
	
	handles[moduleName] = handle;
	
	creationTime[moduleName] = getModificationTime(modFile);
}


void unloadModule(char[] moduleName) {
	int s = dlclose(handles[moduleName]);
	if (s != 0)
		throw new Exception(std.string.format("dlclose(\"%s\"): %s", 
		                                      moduleName, std.string.toString(dlerror())));
	handles.remove(moduleName);
	
	foreach(m; moduleDeps[moduleName]) {
		auto t = moduleRDeps[m].dup;
		foreach(inout v; t)
			moduleRDeps[m].swapout(moduleName);
	}
	moduleDeps.remove(moduleName);
	sourceDeps.remove(moduleName);
	creationTime.remove(moduleName);
}


d_time getModificationTime(char[] file) {
	d_time c,a,m;
	getTimes(file,c,a,m);
	return m;
}