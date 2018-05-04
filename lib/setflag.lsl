#ifndef _INCLUDE_SETFLAG_H_
#define _INCLUDE_SETFLAG_H_

#include "objdesc.lsl"
#define setflag(x) llSetObjectDesc(llGetObjectDesc() + "{" + (x) + "}")

#endif
