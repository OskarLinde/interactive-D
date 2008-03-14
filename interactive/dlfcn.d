module dlfcn;

/* From <dlfcn.h>
*  See http://www.opengroup.org/onlinepubs/007908799/xsh/dlsym.html
*/

const int RTLD_LAZY =   0x00001;
const int RTLD_NOW =    0x00002;
const int RTLD_GLOBAL = 0x00100;

extern(C)
{
    void *dlopen(char* file, int mode);
    int dlclose(void* handle);
    void *dlsym(void* handle, char* name);
    char* dlerror();
}
