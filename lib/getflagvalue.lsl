#ifndef _INCLUDE_GETFLAGVALUE_LSL_
#define _INCLUDE_GETFLAGVALUE_LSL_

#include "objname.lsl"
#include "objdesc.lsl"

string getflagvalue(string flagname) {
   integer i;
   list l = llParseString2List(llGetObjectName() + llGetObjectDesc(), ["{","}"], []);

   for (i = 0; i < llGetListLength(l); i++) {
      if (0 == llSubStringIndex(llList2String(l, i), flagname + ":")) {
         l = llParseString2List(llList2String(l, i), [ ":" ], []);
         return llList2String(l, 1);
      }
   }
   return "";
}

#endif
