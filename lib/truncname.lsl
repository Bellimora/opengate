#ifndef _INCLUDE_TRUNCNAME_LSL_
#define _INCLUDE_TRUNCNAME_LSL_

#include "objname.lsl"
#include "trim.lsl"

#define truncname() \
   trim(llList2String( llParseString2List(llGetObjectName(), [ "[", "{", "(", "<" ], []), 0))

#endif
