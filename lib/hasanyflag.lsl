#ifndef _INCLUDE_HASANYFLAG_LSL_
#define _INCLUDE_HASANYFLAG_LSL_

#include "objname.lsl"
#include "objdesc.lsl"

// Like hasflag, but matches only the beginning.
// typically used as hasanyflag("err_")

#define hasanyflag(s) \
   ( ( -1 != llSubStringIndex(llGetObjectName(), "{"+(s)) ) || \
        ( -1 != llSubStringIndex(llGetObjectDesc(), "{"+(s)) ))

#endif
