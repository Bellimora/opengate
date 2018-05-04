#ifndef _INCLUDE_CLRFLAG_H_
#define _INCLUDE_CLRFLAG_H_

#include "objdesc.lsl"

#define clrflag(x) llSetObjectDesc(strreplace(llGetObjectDesc(), "{" + (x) + "}", ""))

#endif
